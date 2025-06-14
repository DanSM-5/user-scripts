#!/usr/bin/env python

import threading
import webbrowser
import os
import sys
import platform
import argparse
import shutil
import subprocess
import functools
import re
from tkinter import Tk

"""
    Open links in the default browser of the current system.
    By default it will search for a links.txt file but one can be specified with -p flag.
    Another option is add links in the linksString variable withing the script.
    Or links can be read from stdin.

    Args:
    path - Path to file with links
    browser - Browser to use to open files
    delay - Change the waiting time between links open
    separator - Change the separator symbol for linksString
    incognito - Open browser using private session
"""

# privatePath = "C:/Program Files/Google/Chrome/Application/chrome.exe %s --incognito"
# privatePathOld = "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe %s --incognito"
defaultTarget = "links.txt"

# TODO: Consider accepting other comment starts as argument
commentsStart = [ '//', '#', ';', ']' ]

# Links can be added here
linksString = """
"""

delay = 1 # delay between links open
allLinks = []
# TODO:
# Currently separator is only used for linksString.
# Consider adding the option for file or stdin
# or remove linksString entirely.
separator = "\n" # Default separator


charsToEscape = " "  # Add here all characters that you want to escape
charsToEscapeRe = (  # This whole clause is equivalent to:  charsToEscape = r"(?<!\\)( )"
    r"(?<!\\)("
    + r"|".join(map(lambda value: re.escape(value), charsToEscape))
    + r")"
)

# privateFlags = {
#     "firefox": "--private",
#     "chromium": "--incognito"
# }

# Known arguments to start a browser in its private mode.
# Using all to avoid having to match each with their respective browser.
privateArgs = "--private --incognito -inprivate"

# Known locations of common browsers
defaultBrowserPaths = {
    "Linux": {
        "firefox": [
            "/usr/lib/firefox"
        ],
        "chromium": [
            "/usr/bin/chromium-browser"
        ],
        "chrome": [
            "/opt/google/chrome"
        ],
        "brave": [
            "/usr/lib/brave-browser"
        ],
    },
    "Windows": {
        "chromium": [
            os.path.expandvars("$LOCALAPPDATA/Chromium/Application/chrome.exe").replace('\\', '/')
        ],
        "chrome": [
            "C:/Program Files/Google/Chrome/Application/chrome.exe",
            "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
        ],
        "firefox": [
            "C:/Program Files/Mozilla Firefox/firefox.exe",
            "C:/Program Files (x86)/Mozilla Firefox/firefox.exe",
        ],
        "librewolf": [
            "C:/Program Files/LibreWolf/librewolf.exe"
        ],
        "brave": [
            os.path.expandvars(
                "$LOCALAPPDATA/BraveSoftware/Brave-Browser/Application/brave.exe"
            ).replace('\\', '/')
        ],
        "edge": [
            "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
        ]
    }
}

parser = argparse.ArgumentParser(prog = 'linksOpener', description = 'Open links in from a file to the browser.')
parser.add_argument('-i', '--incognito', action = argparse.BooleanOptionalAction, default = False, help = 'Open links in a private session.')
parser.add_argument('-p', '--path', action = 'store', default = 'links.txt', help = 'Path with links to open in browser.')
parser.add_argument('-d', '--delay', action = 'store', default = 1, help = 'Delay in seconds to use for opening links.', type = int)
parser.add_argument('-b', '--browser', action = 'store', default = '', help = 'Name or path of browser to use')
parser.add_argument('-s', '--separator', action = 'store', default = '\n', help = 'Separator for link in the file. Line break is the default.')
parser.add_argument('-c', '--clipboard', action = argparse.BooleanOptionalAction, default = False, help = 'Get links from clipboard')
parser.add_argument('--debug', action = argparse.BooleanOptionalAction, default = False, help = 'Add additional logs in the console for debug.')
parser.add_argument('infile', nargs='?', type = argparse.FileType('rb'), default = None, help = 'File to read. Use [-] to read from stdin. WARNING: empty stdin will hang the script.')

args = parser.parse_args()

systemOs = platform.system()
delay = args.delay or delay
separator = args.separator or separator

# Required for windows if using default browser
if systemOs == "Windows":
    from winreg import HKEY_CLASSES_ROOT, HKEY_CURRENT_USER, OpenKey, QueryValueEx

debug = lambda *debugArgs: print('[Links Opener]', *debugArgs) if args.debug else lambda: None


def escapeSpaces(stringToEscape):
    """ Escape all non-escaped spaces in the string to escape """
    return re.sub(charsToEscapeRe, r'\\\1', stringToEscape)

def buildPrivateCommand(commandPath):
    browserPath = escapeSpaces(commandPath)
    return f'{browserPath} %s {privateArgs}'

def preparePath(stringPath):
    return escapeSpaces(stringPath.replace('\\', '/'))

def getWindowsDefaultBrowser():
    browser_path = ''

    # Find the default browser by checking the registry
    try:

        with OpenKey(HKEY_CURRENT_USER, r'SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice') as regkey:
            # Get the user choice
            browser_choice = QueryValueEx(regkey, 'ProgId')[0]

        with OpenKey(HKEY_CLASSES_ROOT, r'{}\shell\open\command'.format(browser_choice)) as regkey:
            # Get the application the user's choice refers to in the application registrations
            browser_path_tuple = QueryValueEx(regkey, None)

            # This is a bit sketchy and assumes that the path will always be in double quotes
            browser_path = browser_path_tuple[0].split('"')[1]

            # Need to change '\' with '/' so it works in webbrowser
            return browser_path.replace('\\', '/')
    except Exception:
        return None

def getLinuxDefaultBrowser():
    # TODO: Find a better strategy as current is a bit hacky

    # Try get default config from xdg-settings. It should return a .desktop file
    # Then try matching with common known browsers and see if they are callable

    common_browsers = (
        'firefox',
        'brave',
        'mozilla-firefox',
        'google-chrome',
        'chrome',
        'chromium',
        'chromium-browser'
    )

    try:
        cmd = "xdg-settings get default-web-browser".split()
        raw_result = subprocess.check_output(cmd, stderr=subprocess.DEVNULL)
        # E.g. "firefox.desktop"
        result = raw_result.decode().strip()
    except Exception:
        return None

    if result.endswith('.desktop'):
        result = result.replace('.desktop', '')

    for browser in common_browsers:
        if (result in browser) and shutil.which(browser):
            # Default browser found
            return result

    return None

def getPrivateBrowserCmd(browserPath):
    if browserPath:
        # If browserPath exist or it is available in the path, compose the launch command
        if os.path.exists(browserPath) or shutil.which(browserPath):
            return buildPrivateCommand(browserPath)
        else:
            return None
    # Add script specific variable to avoid conflicts with BROWSER
    elif 'BROWSER_LINKSOPENER' in os.environ:
        return buildPrivateCommand(os.environ["BROWSER_LINKSOPENER"])
    # Respect browser env variable
    elif 'BROWSER' in os.environ:
        return buildPrivateCommand(os.environ["BROWSER"])
    else:
        defaultBrowser = None

        if systemOs == "Windows":
            defaultBrowser = getWindowsDefaultBrowser()
        elif systemOs == "Linux":
            defaultBrowser = getLinuxDefaultBrowser()

        if defaultBrowser:
            return buildPrivateCommand(defaultBrowser)
        else:
            return None

class Opener:
    """Wrapper for webbrowser to add additional features like open in incognito/private session"""
    def __init__(self, browserPath = None, isPrivate = False):
        debug(f'Browser: {browserPath}')
        debug(f'Is private session? {isPrivate}')
        self.browser = webbrowser.get(using = browserPath)
        self.isPrivate = isPrivate
        
    def open(self, link):
        self.browser.open(link)

    def recursiveOpen(self, linksIterator, current = None):
        link = current

        if not link:
            link = linksIterator.next()

        if args.debug:
            debug(f'Opening: {link}')
        elif not self.isPrivate:
            print(f'Opening: {link}')

        self.open(link)
        nextLink = linksIterator.next()

        if nextLink:
            threading.Timer(
                delay,
                functools.partial(self.recursiveOpen, linksIterator, nextLink)
            ).start()
        else:
            print("All links opened!")

class Iterator:
    """Combine different generators under the same interface"""
    # Accepts multi line string, file handler or path to file.
    def __init__(self, iterators):
        self.iterators = []

        for iterator in iterators:
            if isinstance(iterator, str):
                if iterator == 'clipboard':
                    self.iterators.append(self.getFromClipboard())
                elif os.path.exists(iterator):
                    self.iterators.append(self.creatFileHandlerGenerator(iterator))
                else:
                    self.iterators.append(iterator.strip().split(separator))
            else:
                self.iterators.append(iterator)

        self.mainIterator = iter(self.yieldNext())

    def getFromClipboard(self):
        # Requires win32clipboard package
        # import win32clipboard
        # set clipboard data
        # win32clipboard.OpenClipboard()
        # win32clipboard.EmptyClipboard()
        # win32clipboard.SetClipboardText('testing 123')
        # win32clipboard.CloseClipboard()

        # get clipboard data
        # win32clipboard.OpenClipboard()
        # data = win32clipboard.GetClipboardData()
        # win32clipboard.CloseClipboard()
        # return data
        clipboard_content = Tk().clipboard_get()
        return clipboard_content.strip().split(separator)

    def creatFileHandlerGenerator(self, path):
        with open(path, 'rb') as fileHandler:
            for line in fileHandler:
                yield line

    def yieldNext(self):
        for iterator in self.iterators:
            for line in iterator:
                if getattr(line, 'decode', None):
                    text = line.decode('utf-8')
                else:
                    text = line

                link = text.strip()

                if not link:
                    continue

                if any(link.startswith(i) for i in commentsStart):
                    continue

                yield link

    def next(self):
        try:
            return next(self.mainIterator)
        except StopIteration:
            return None

def requestContinuation():
    # In order to append command line arguments to open in private/incognito mode
    # we need the command or path to provide to webbrowser module.
    # Failure to compose the string will result in the inavility to open the
    # browser in private mode.

    print(
        'Request to open links was made using a private session.',
        'However browser path was not provided or not found and default browser location couldn\'t be found.',
        'It is not possible to append command line arguments without a browser command or path.',
        'Links opening process can proceed with default or requested browser in a normal session.',
        sep = os.linesep
    )

    answer = str(input('Do you wish to proceed? [Y/y]: '))

    try:
        return answer.lower()[0] == 'y' if answer else False
    except Exception:
        return False

def main():
    browserPath = None
    allLinks = []
    pathToFile = args.path or defaultTarget

    # Use browser argument if present
    if args.browser:
        # Provided name of browser
        if args.browser in defaultBrowserPaths[systemOs]:
            for location in defaultBrowserPaths[systemOs][args.browser]:
                if os.path.exists(location):
                    browserPath = location
                    break
        # Provided path to browser
        elif os.path.exists(args.browser) or shutil.which(args.browser):
            browserPath = args.browser.replace('\\', '/') # Make sure path uses '/'
        # Is a valid browser for webbrowser
        elif webbrowser._browsers and args.browser in webbrowser._browsers:
            browserPath = args.browser
        else:
            print('Invalid browser. Using system default browser')

    # If incognito, try creating a command line with private flags
    if args.incognito:
        privateBrowser = getPrivateBrowserCmd(browserPath)

        if privateBrowser is None:
            shouldContinue = requestContinuation()

            if shouldContinue:
                # Set to None so that webbrowser will find the default browser
                browserPath = escapeSpaces(browserPath) if browserPath else None
            else:
                print('Terminating process')
                sys.exit(1)
                return
        else:
            browserPath = privateBrowser
    # Need to escape espaces in order to work with webbrowser
    elif browserPath and os.path.exists(browserPath):
        # NOTE: webbrowser has a bug in which providing a path will
        # result in a browser not found unless you register the browser first
        # however webbrowser handles it correctly when '%s' is present as
        # it is consider a command line. Use the command line trick for simplicity.
        browserPath = preparePath(browserPath) + ' %s'
    # If browser is None, check if there is a browser in the environment variables
    elif browserPath is None:
        # Add script specific variable to avoid conflicts with BROWSER
        if 'BROWSER_LINKSOPENER' in os.environ:
            browserPath = preparePath(os.environ["BROWSER_LINKSOPENER"]) + ' %s'
        # Respect browser env variable
        elif 'BROWSER' in os.environ:
            browserPath = preparePath(os.environ["BROWSER"]) + ' %s'

    if linksString.strip():
        allLinks.append(linksString)

    if os.path.exists(pathToFile):
        allLinks.append(pathToFile)

    if args.infile:
        allLinks.append(args.infile)

    if args.clipboard:
        allLinks.append('clipboard')

    if len(allLinks):
        iterator = Iterator(allLinks)
        opener = Opener(browserPath, args.incognito)

        opener.recursiveOpen(iterator)
    else:
        print('No links to open. Ending.')

if __name__ == "__main__":
    main()
