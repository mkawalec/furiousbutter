task 'watch', 'Watch source for changes', ->
    coffee = spawn 'coffee', ['-w', '-c', '-l', '-o', 'static/js', 'coffee']
    coffee.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    coffee.stdout.on 'data', (data) ->
        print data.toString()


fs = require 'fs'
{print} = require 'sys'
{spawn} = require 'child_process'
{writeFile} = require 'fs'
_ = require 'underscore'

try
    UglifyJS = require("uglify-js")
catch e
    if e.code == 'MODULE_NOT_FOUND'
        return
    throw e

build = (callback) ->
    ls = spawn 'ls', ['coffee']

    ls.stdout.on 'data', (data) ->
        console.log "Building the backend..."
        for row in data.toString().split('\n')
            if not row.match /\.litcoffee/
                continue
            coffee = spawn 'coffee', ['-p', '-c', '-l', 'coffee/'+row]
            ((row) ->
                coffee.stdout.on 'data', (output) ->
                    filename = 'static/js/'+row.match(/\w*/)[0]
                    print 'writing ' + filename + '\n'
                    writeFile filename+'.js', output.toString(), (err) ->
                        if err then throw err

                    if UglifyJS?
                        final_code = UglifyJS.minify(output.toString(), {fromString: true}).code
                        writeFile filename+'.min.js', final_code, (err) ->
                            if err then throw err

                coffee.stderr.on 'data', (data) ->
                    process.stderr.write data.toString()
                coffee.on 'exit', (code) ->
                    callback?() if code is 0
            )(row)

    compile_themes()

compile_themes = ->
    theme_list = spawn 'ls', ['themes']
    theme_list.stdout.on 'data', (data) ->
        console.log "\nBuilding themes..."
        _.each _.filter(data.toString().split('\n'), (i) -> i.length > 0), (theme) ->
            console.log "Building theme #{theme}"
            spawn 'cake', ['build'], {cwd: "themes/#{theme}"}

task 'build', 'Build from src', ->
    build()
