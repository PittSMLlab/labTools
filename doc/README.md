# How to generate new docs?

1. Add [m2html](https://github.com/gllmflndn/m2html) to your path.

2. First cd into the lab tools folder `/home/foo/labTools/`
```
cd('/home/foo/labTools')
```

3. OPTIONAL. Only do this step if you want to rebuild doc for the entier repo. Remove the current doc folder. This won't be necessary for addition of files, or code chanes inside existing files. This step only becomes useful if the structures of the repository have changed a lot or a lot of older files don't exist anymore. This allows you to remove docs for files that doesn't exist any more such that the doc captures the current state of the labtools.
```
mkdir('temp3')
%save the user guide doc and read me file
movefile 'doc/LabTools User Guide.doc' 'temp3/LabTools User Guide.doc'
movefile 'doc/LabTools User Guide.pdf' 'temp3/LabTools User Guide.pdf'
movefile 'doc/README.md' 'temp3/README.md'
%s flag allows removing non empty folders.
rmdir('/home/foo/labTools/doc','s')
```

4. Now rebuild or update the docs
```
%do this for each folder, do this such that html docs are under doc/ direclty, rathre than doc/labtools/
m2html('mfiles','gui', 'htmldir','doc', 'recursive','on','verbose','on');
m2html('mfiles','classes', 'htmldir','doc', 'recursive','on','verbose','on');
m2html('mfiles','fun', 'htmldir','doc', 'recursive','on','verbose','on');
m2html('mfiles','example', 'htmldir','doc', 'recursive','on','verbose','on');
```

5. OPTIONAL. If you had done step 3, not move the read me and user guide back and clean up temp 3.
```
movefile 'temp3/LabTools User Guide.doc' 'doc/LabTools User Guide.doc'
movefile 'temp3/LabTools User Guide.pdf' 'doc/LabTools User Guide.pdf'
movefile 'temp3/README.md' 'doc/README.md'
rmdir('temp3','s')
```
