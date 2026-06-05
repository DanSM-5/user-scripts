#!/usr/bin/env node
'use strict';
/**
 * unstage.js  —  Node port of unstage.py
 *
 * Unstage specific staged lines (split a staged hunk) non-interactively, by
 * rebuilding a subset patch and reverse-applying it to the index:
 *   git diff --cached -- <file>  |  filter  |  git apply --cached -R --recount
 *
 * Usage:
 *   node unstage.js [--sync | --async] [--dry-run] <file> <spec> [<spec> ...]
 *
 * Flags (in addition to the positional args):
 *   --sync       run git via child_process.execFileSync   (default)
 *   --async      run git via child_process.execFile (promisified, stdin piped)
 *   --dry-run    print the computed patch instead of applying it
 *   -h, --help   show this help
 *
 * Specs — a range of NEW-file (working/index) line numbers, i.e. the line
 * numbers your editor's gutter shows. A range UNDOES ANY staged change it
 * covers, with no need to say "add" or "delete":
 *   N        single line
 *   N-M      range N..M inclusive
 *   -N       from line 1 to N
 *   N-       from line N to end
 *
 * Semantics within a range:
 *   - a staged addition (+) on a covered new-file line  -> unstaged
 *   - a staged deletion (-) at a covered new-file position -> re-included
 *   - a modified line (a -/+ pair) shares one new-file number, so a single
 *     range value undoes both halves at once.
 * A deletion has no new-file line of its own; it is matched by the new-file
 * position it was removed from (the gap), so e.g. deleting the last line is
 * covered by a range reaching one past the final line (use "N-").
 *
 * Compatible with the Node bundled by VS Code (tested syntax on Node 14–22),
 * CommonJS, no ESM-only syntax, no top-level await.
 */
var cp = require('child_process');
var execFile = cp.execFile;
var execFileSync = cp.execFileSync;

var MAX_BUFFER = 64 * 1024 * 1024; // 64 MiB, for large staged diffs

function usage() {
  process.stderr.write(
    'Usage: node unstage.js [--sync|--async] [--dry-run] <file> <spec> [<spec> ...]\n' +
      '  spec: N | N-M | -N | N-   (NEW-file line numbers; undoes any staged change in range)\n',
  );
}

// ---- spec parsing -> array of intervals [lo, hi]; hi=null means open-ended ----
function parseSpecs(specs) {
  var intervals = [];
  for (var i = 0; i < specs.length; i++) {
    var s = specs[i].trim();
    var lo, hi;
    var dash = s.indexOf('-');
    if (dash !== -1) {
      var loStr = s.slice(0, dash);
      var hiStr = s.slice(dash + 1);
      lo = loStr === '' ? 1 : parseInt(loStr, 10); // "-N" -> 1..N
      hi = hiStr === '' ? null : parseInt(hiStr, 10); // "N-" -> N..end
    } else {
      lo = hi = parseInt(s, 10); // "N"  -> N..N
    }
    intervals.push([lo, hi]);
  }
  return intervals;
}

function selected(n, intervals) {
  for (var i = 0; i < intervals.length; i++) {
    var lo = intervals[i][0],
      hi = intervals[i][1];
    if (lo <= n && (hi === null || n <= hi)) return true;
  }
  return false;
}

// ---- rebuild the subset patch from `git diff --cached` output ----
// Both additions and deletions are matched against the NEW-file line counter:
//   '+' uses its own new-file line number;
//   '-' uses the current new-file position (the gap it was removed from).
function buildPatch(diff, intervals) {
  var lines = diff.split('\n');
  if (lines.length && lines[lines.length - 1] === '') lines.pop(); // mirror Python splitlines()
  var out = [];
  var newLn = 0,
    inHunk = false;
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (
      line.indexOf('diff ') === 0 ||
      line.indexOf('index ') === 0 ||
      line.indexOf('--- ') === 0 ||
      line.indexOf('+++ ') === 0
    ) {
      out.push(line);
      continue; // file headers
    }
    if (line.indexOf('@@') === 0) {
      out.push(line); // --recount fixes the numbers
      // @@ -old_start,old_len +new_start,new_len @@  -> seed new-file counter
      var seg = line.split('@@')[1].trim();
      var parts = seg.split(' ');
      newLn = parseInt(parts[1].slice(1).split(',')[0], 10); // strip leading '+'
      inHunk = true;
      continue;
    }
    if (!inHunk) {
      out.push(line);
      continue;
    } // extended headers (mode/rename/etc.)
    var tag = line.charAt(0);
    var text = line.slice(1);
    if (tag === ' ') {
      // context: present on both sides
      out.push(line);
      newLn++;
    } else if (tag === '+') {
      // addition: index side only
      out.push(selected(newLn, intervals) ? line : ' ' + text); // keep -> unstage; else context
      newLn++;
    } else if (tag === '-') {
      // deletion: matched by new-file position
      if (selected(newLn, intervals)) out.push(line); // keep -> reverse-apply re-includes it
      // else: drop it (stays staged; not present in index, can't be context)
      // newLn is NOT advanced: a deletion occupies no new-file line.
    } else {
      out.push(line); // "\ No newline at end of file", etc.
    }
  }
  return out.join('\n') + '\n';
}

// ---- git runners: one per requested mechanism ----
function gitSync(gitArgs, input) {
  var opts = { encoding: 'utf8', maxBuffer: MAX_BUFFER };
  if (input != null) opts.input = input;
  return execFileSync('git', gitArgs, opts);
}

function gitAsync(gitArgs, input) {
  return new Promise(function (resolve, reject) {
    var child = execFile(
      'git',
      gitArgs,
      { encoding: 'utf8', maxBuffer: MAX_BUFFER },
      function (err, stdout, stderr) {
        if (err) {
          err.message += stderr ? '\n' + stderr : '';
          reject(err);
        } else resolve(stdout);
      },
    );
    if (input != null) child.stdin.end(input); // pipe patch to git apply's stdin
  });
}

// ---- arg parsing: long flags + -h are flags; everything else (incl. "-N" specs) is positional ----
function parseArgs(argv) {
  var mode = 'sync',
    dryRun = false,
    positional = [];
  for (var i = 0; i < argv.length; i++) {
    var a = argv[i];
    if (a === '--sync') mode = 'sync';
    else if (a === '--async') mode = 'async';
    else if (a === '--dry-run') dryRun = true;
    else if (a === '-h' || a === '--help') {
      usage();
      process.exit(0);
    } else if (a === '--') {
      /* end-of-flags separator */
    } else if (a.indexOf('--') === 0) {
      process.stderr.write('Unknown flag: ' + a + '\n');
      usage();
      process.exit(2);
    } else positional.push(a); // "-10", "80-", "10-20", filename, ...
  }
  return { mode: mode, dryRun: dryRun, positional: positional };
}

function main() {
  var parsed = parseArgs(process.argv.slice(2));
  if (parsed.positional.length < 2) {
    usage();
    process.exit(2);
  }
  var file = parsed.positional[0];
  var intervals = parseSpecs(parsed.positional.slice(1));

  // Unify both mechanisms behind a promise; the body is identical either way.
  var runGit =
    parsed.mode === 'async'
      ? gitAsync
      : function (gitArgs, input) {
          return Promise.resolve(gitSync(gitArgs, input));
        };

  return runGit(['diff', '--cached', '--', file]).then(function (diff) {
    if (!diff || !diff.trim()) {
      process.stderr.write('No staged changes for ' + file + '\n');
      process.exit(1);
    }
    var patch = buildPatch(diff, intervals);
    if (parsed.dryRun) {
      process.stdout.write(patch);
      return;
    }
    return runGit(['apply', '--cached', '-R', '--recount'], patch).then(
      function () {
        process.stderr.write(
          'Unstaged selected lines from ' +
            file +
            ' (git via ' +
            (parsed.mode === 'async' ? 'execFile' : 'execFileSync') +
            ').\n',
        );
      },
    );
  });
}

module.exports = {
  parseSpecs: parseSpecs,
  selected: selected,
  buildPatch: buildPatch,
};

if (require.main === module) {
  Promise.resolve()
    .then(main)
    .catch(function (e) {
      process.stderr.write((e && e.message ? e.message : String(e)) + '\n');
      process.exit(1);
    });
}
