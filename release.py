#!/usr/bin/env python

import sys
import os
import errno
import urllib
import zipfile
import subprocess
import shutil

GAME_ID = "norsegame"

LOVE_WIN64 = "https://bitbucket.org/rude/love/downloads/love-0.9.2-win64.zip"
LOVE_WIN32 = "https://bitbucket.org/rude/love/downloads/love-0.9.2-win32.zip"
LOVE_OSX = "https://bitbucket.org/rude/love/downloads/love-0.9.2-macosx-x64.zip"

RELEASE_DIR = os.path.join(os.path.dirname(os.path.realpath(__file__)), "release")
TMP_DIR = os.path.join(RELEASE_DIR, "tmp")
LOVE_FILE = os.path.join(RELEASE_DIR, GAME_ID + ".love")

def build_lovefile():
	print "-- Creating " + LOVE_FILE + " --"
	with zipfile.ZipFile(LOVE_FILE, 'w') as love_zip:
		files = subprocess.check_output(["git", "ls-files"]).splitlines()
		for f in files: love_zip.write(f)
	print "-- Created " + LOVE_FILE + " --"

def build_osx():
	raise NotImplementedError()

def build_windows(use32bit):
	print "-- Building for Windows " + ("32" if use32bit else "64") + "-bit --"
	love_zip = os.path.join(TMP_DIR, "love.zip")
	urllib.urlretrieve(LOVE_WIN32 if use32bit else LOVE_WIN64, love_zip)
	with zipfile.ZipFile(love_zip, 'r') as love_zipfile: love_zipfile.extractall(TMP_DIR)
	love_folder = os.path.join(TMP_DIR, "love-0.9.2-win32" if use32bit else "love-0.9.2-win64")

	with open(os.path.join(love_folder, GAME_ID + ".exe"), 'wb') as game_exe:
		shutil.copyfileobj(open(os.path.join(love_folder, "love.exe"), "rb"), game_exe)
		shutil.copyfileobj(open(LOVE_FILE, "rb"), game_exe)

	os.remove(os.path.join(love_folder, "love.exe"))
	OUT_DIR = GAME_ID + "-win32" if use32bit else GAME_ID + "-win64"
	shutil.move(love_folder, os.path.join(RELEASE_DIR, OUT_DIR))
	shutil.make_archive(os.path.join(RELEASE_DIR, OUT_DIR), "zip", root_dir=os.path.join(RELEASE_DIR, OUT_DIR))

def make_directory(path, clear):
	# Might want to clear directory
	if clear and os.path.isdir(path):
		shutil.rmtree(path)

	# Try to create the directory
	try: os.makedirs(path)
	except OSError as err:
		# If directory already exists, continue
		if err.errno == errno.EEXIST: pass
		else: raise err

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print "One argument required."
		sys.exit(1)

	print "-- Norse Game Release Script --"

	make_directory(RELEASE_DIR, False)
	make_directory(TMP_DIR, True)
	
	build_lovefile()

	if sys.argv[1] == "win32":
		build_windows(True)
	elif sys.argv[1] == "win64":
		build_windows(False)
	elif sys.argv[1] == "love":
		pass
	elif sys.argv[1] == "osx":
		build_osx()
	else:
		print "Unkown platform"
		sys.exit(1)