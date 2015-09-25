path        = require 'path'
sqlite3     = require 'sqlite3'
fs          = require 'fs'
gulp        = require 'gulp'
coffeelint  = require 'gulp-coffeelint'
coffee      = require 'gulp-coffee'
del         = require 'del'
watch       = require 'gulp-watch'
rewrite     = require 'gulp-bitwig-rewrite-meta'
data        = require 'gulp-data'

# paths, misc settings
$ =
  serumPresetDB: '/Library/Audio/Presets/Xfer\ Records/Serum\ Presets/System/presetdb.dat'
  rawPresetsDir: "./raw"
  deployDir: "#{process.env.HOME}/Documents/Bitwig Studio/Library/Presets/Serum"
  distDir: "./Serum"
  query: '''
select
  PresetDisplayName
  ,PresetRelativePath
  ,Author
  ,Description
  ,Category
from
  SerumPresetTable
where
  PresetDisplayName = $name
  and PresetRelativePath = $folder
'''

gulp.task 'coffeelint', ->
  gulp.src ['./*.coffee']
    .pipe coffeelint './coffeelint.json'
    .pipe coffeelint.reporter()


# rewrite metadata
gulp.task 'rewrite_meta', ->
  # open database
  db = new sqlite3.Database $.serumPresetDB, sqlite3.OPEN_READONLY
  gulp.src ["#{$.rawPresetsDir}/**/*.bwpreset"], read: true
    .pipe data (file, cb) ->
      params =
        $name: path.basename file.path, '.bwpreset'
        $folder: path.relative $.rawPresetsDir, path.dirname file.path
      db.get $.query, params, cb
    .pipe rewrite (file, data) ->
      creator: file.data.Author?.trim()
      preset_category: file.data.Category?.trim()
      comment: file.data.Description?.trim()
    .pipe gulp.dest $.distDir
    .on 'end', ->
      db.close()
      
# deploy preset file to bitwig library folder
gulp.task 'deploy', ->
  gulp.src ["#{$.distDir}/**/*.bwpreset"]
    .pipe gulp.dest $.deployDir


gulp.task 'default', [
  'coffeelint'
  'rewrite_meta'
]

gulp.task 'watch', ->
  gulp.watch './*.coffee', ['default']
 
gulp.task 'clean', (cb) ->
  del ['./**/*~', $.distDir, $.deployDir], force: true, cb
