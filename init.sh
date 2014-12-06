#!/bin/bash

#
# This scripts set up a newly checkout out repository for bloging with.
#


#
# All work and temporary files are done in the branch source:
#
git checkout source


#
# When we create a blog (see below)
# We push all changes into the _Deploy directory.
# Which is also the master branch (github displays the master branch (generated html))
git clone git@github.com:Loki-Astari/loki-astari.github.io.git _Deploy


#
# Some simple Help
echo 'To create a new blog post article:'
echo 'rake post["Title"]'
echo
echo 'To generate the blog from markdown:'
echo 'rake generate'
echo
echo 'To publish the blog:'
echo 'Note: This copies all the generated files from public to _Deply. Then commits the changes files and pushes them to github'
echo 'Note: Because the files were put in _Deploy they are on the master branch (see above)'
echo 'rake deploy'
