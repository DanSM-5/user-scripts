#!/usr/bin/env python

import threading
import webbrowser
import os
import sys
import platform
import argparse
import shutil
import subprocess

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

privateFlags = {
    "firefox": "--private",
    "chromium": "--incognito"
}

privateArgs = "--private --incognito"

# Known locations of common browsers
defaultBrowserPaths = {
    "Linux": {
        "firefox": [],
        "chromium": [
            "/usr/bin/chromium-browser"
        ],
    },
    "Windows": {
        "chromium": [],
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
        "edge": [
            "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
        ]
    }
}

parser = argparse.ArgumentParser(prog = 'linksOpener', description = 'Open links in from a file to the browser.')
parser.add_argument('-i', '--incognito', action = argparse.BooleanOptionalAction, default = False, help = 'Open links in a private session.')
parser.add_argument('-p', '--path', action = 'store', default = 'links.txt', help = 'Path with links to open in browser.')
parser.add_argument('-d', '--delay', action = 'store', default = 1, help = 'Delay in seconds to use for opening links.', type = int)
parser.add_argument('-b', '--browser', action = 'store', default = '', help = 'Delay in seconds to use for opening links.')
parser.add_argument('-s', '--separator', action = 'store', default = '\n', help = 'Separator for link in the file. Line break is the default.')

args = parser.parse_args()

systemOs = platform.system()
delay = args.delay or delay
separator = args.separator or separator

# Required for windows if using default browser
if systemOs == "Windows":
    from winreg import HKEY_CLASSES_ROOT, HKEY_CURRENT_USER, OpenKey, QueryValueEx

def buildPrivateCommand(browserPath):
    return f'{browserPath} %s {privateArgs}'

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
    # Respect browser env variable
    elif 'BROWSER' in os.environ:
        return buildPrivateCommand(f'{os.environ["BROWSER"]}')
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
    def __init__(self, browserPath = None):
        # print(f'Using browser {browserPath}')
        self.browser = webbrowser.get(using = browserPath)
        
    def open(self, link):
        self.browser.open(link)

    def recursiveOpen(self, links, current = 0):
        link = links[current]
        self.open(link)
        next = current + 1
        if next < len(links):
            threading.Timer(delay, lambda: self.recursiveOpen(links, next)).start()
        else:
            print("All links opened!")

def getLinksFromFile(file):
    links = []
    lines = ''

    with open(file, "r") as f:
        lines = f.readlines()

    for l in lines:
        if not l:
            continue

        line = l.strip()

        if any(line.startswith(i) for i in commentsStart):
            continue

        links.append(line)

    return links

def getLinksFromStdin():
    links = []

    for l in sys.stdin:
        if not l:
            continue

        line = l.strip()

        if any(line.startswith(i) for i in commentsStart):
            continue

        links.append(line)

    return links

def requestContinuation():
    # In order to append command line arguments to open in private/incognito mode
    # we need the command or path to provide to webbrowser module.
    # Failure to compose the string will result in the inavility to open the
    # browser in private mode.

    print('Request to open links was made using a private session.')
    print('However browser was not provided or not found and default browser location couldn\'t be found.')
    print('It is not possible to append command line arguments without a browser command or path.')
    print('Links opening process can proceed with default browser but it would happen in a normal session.')
    answer = str(input('Do you wish to proceed? [Y/y]: '))

    try:
        return answer.lower()[0] == 'y' if answer else False
    except Exception:
        return False

def main():
    browserPath = None

    if args.browser:
        # Provided name of browser
        if args.browser in defaultBrowserPaths[systemOs]:
            for location in defaultBrowserPaths[systemOs][args.browser]:
                if os.path.exists(location):
                    browserPath = location
                    break
        # Provided path to browser
        elif os.path.exists(args.browser) or (shutil.which(args.browser) is not None):
            browserPath = args.browser
        else:
            print('Invalid browser. Using system default browser')

    if args.incognito:
        privateBrowser = getPrivateBrowserCmd(browserPath)

        if privateBrowser is None:
            shouldContinue = requestContinuation()

            if shouldContinue:
                # Set to None so that webbrowser will find the default browser
                browserPath = None
            else:
                print('Terminating process')
                sys.exit(1)
                return
        else:
            browserPath = privateBrowser

    # Get any link from linksString.
    allLinks = [l for l in linksString.split(separator) if l]

    linksFile = args.path or defaultTarget

    # Get links from file.
    if os.path.exists(linksFile):
        fromFile = getLinksFromFile(linksFile)
        allLinks.extend(fromFile)

    # Links from STDIN
    fromStdin = getLinksFromStdin()
    if len(fromStdin):
        allLinks.extend(fromStdin)

    if len(allLinks):
        opener = Opener(browserPath)
        opener.recursiveOpen(allLinks)
    else:
        print('No links to open. Ending.')

if __name__ == "__main__":
    main()
