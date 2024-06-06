# How to generate new docs?

1. Add [m2html](https://github.com/gllmflndn/m2html) to your path.

2. First cd into the lab tools' parent folder. For example, if labtool is at `/home/foo/labTools/`, then go to `/home/foo`
```
cd('/home/foo/')
```

3. OPTIONAL. Remove the current doc folder.  Only do this step if you want to rebuild doc for the entire repo. This won't be necessary for addition of files, or code changes inside existing files. This step only becomes useful if the structures of the repository have changed a lot or a lot of older files don't exist anymore. This allows you to remove docs for files that doesn't exist any more such that the doc captures the current state of the labtools.
```
mkdir('temp3')
%save the user guide doc and read me file
movefile 'labTools/doc/LabTools User Guide.doc' 'temp3/LabTools User Guide.doc'
movefile 'labTools/doc/LabTools User Guide.pdf' 'temp3/LabTools User Guide.pdf'
movefile 'labTools/doc/README.md' 'temp3/README.md'
%s flag allows removing non empty folders.
rmdir('/home/foo/labTools/doc','s')
```

4. Now rebuild the docs. If you didn't remove the old folder, this will simply make updates on existing html files, but it will not remove old html file that represents doc for functions that don't exist anymore.
```
m2html('mfiles','labTools', 'htmldir','labTools/doc','recursive','on','verbose','on')
```

5. OPTIONAL. If you had done step 3, now move the read me and user guide back to the doc folder and clean up temp 3.
```
movefile 'temp3/LabTools User Guide.doc' 'labTools/doc/LabTools User Guide.doc'
movefile 'temp3/LabTools User Guide.pdf' 'labTools/doc/LabTools User Guide.pdf'
movefile 'temp3/README.md' 'labTools/doc/README.md'
rmdir('temp3','s')
```
