#!/usr/bin/env python

import threading
import webbrowser
import os
import sys
import platform
import argparse

"""
    Open links in the default browser of the current system.
    By default it will search for a links.txt file but one can be specified with -p flag.
    Another option is add links in the linksString variable withing the script.

    delay - Change the waiting time between links open
    separator - change the separator symbol for linksString
"""

privatePath = "C:/Program Files/Google/Chrome/Application/chrome.exe %s --incognito"
privatePathOld = "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe %s --incognito"
defaultTarget = "linksOpener.txt"

commentsStart = [ '//', '#', ';', ']' ]

linksString = """
"""

delay = 1 # delay between links open
separator = "\n" # Default separator

defaultBrowserPaths = {
    "Linux": {
        "normal": [],
        "private": []
    },
    "Windows": {
        "normal": [
            "C:/Program Files/Google/Chrome/Application/chrome.exe",
            "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
        ],
        "private": [
            "C:/Program Files/Google/Chrome/Application/chrome.exe %s --incognito",
            "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe %s --incognito"
        ],
    }
}

parser = argparse.ArgumentParser(prog = 'linksOpener', description = 'Open links in from a file to the browser.')
parser.add_argument('-i', '--incognito', action = argparse.BooleanOptionalAction, default = False, help = 'Open links in a private session.')
parser.add_argument('-p', '--path', action = 'store', default = 'links.txt', help = 'Path with links to open in browser.')
parser.add_argument('-s', '--separator', action = 'store', default = '\n', help = 'Separator for link in the file. Line break is the default.')
parser.add_argument('-d', '--delay', action = 'store', default = 1, help = 'Delay in seconds to use for opening links.', type = int)
parser.add_argument('-b', '--browser', action = 'store', default = '', help = 'Delay in seconds to use for opening links.')

args = parser.parse_args()

systemOs = platform.system()

browserLocation = args.browser
privateSession = 'private' if args.incognito else 'normal'

browserOptions = defaultBrowserPaths[systemOs][privateSession]

if not browserLocation:
    print(browserOptions)
    for location in browserOptions:
        if os.path.exists(location):
            browserLocation = location
            break

# Set Chrome location
# if not os.path.exists(privatePath):
    # privatePath = privatePathOld

print(args)
print(browserLocation)
answer = str(input('Use private browser? [Y/y]: '))

def main():
    askHistory = True
    target = None

    for i, arg_val in enumerate(sys.argv):
        if arg_val.startswith('-'):
            if arg_val == '-h':
                askHistory = False
                saveHistory = False
            elif arg_val == '-p' and sys.argv[i + 1]:
                target = sys.argv[i + 1]
            else:
                continue
        continue
                
    if askHistory:
        answer = str(input(f'Use private browser? [Y/y]({target}): '))
        if answer.lower() == "y":
            saveHistory = False
        else:
            saveHistory = True

    # privatePath = "C:/Program Files/Google/Chrome/Application/chrome.exe %s --incognito"
    links = [l for l in linksString.split(separator) if l]
    counter = { "val": 0 }
    if target:
        linksFile = target
    else:
        linksFile = f'{defaultTarget}'

    # get links from file linksOpener.txt
    if os.path.exists(linksFile):
        with open(linksFile, "r") as f:
            lines = f.readlines()

        for l in lines:
            if l:
                line = l.strip()
                if any(line.startswith(i) for i in commentsStart):
                    continue
                else:
                    links.append(line)

    total = len(links)
    usingPath = privatePath if not saveHistory else None
    browser = webbrowser.get(using=usingPath)

    def opener(link):
        browser.open(link)
        counter["val"] += 1
        if total > counter["val"]:
            next = links[counter["val"]]
            threading.Timer(delay, lambda: opener(next)).start()
        else:
            print("All links opened!")

    if total > counter["val"]:
        opener(links[counter["val"]])
    else:
        print("No links")

if __name__ == "__main__":
    # main()
    pass
