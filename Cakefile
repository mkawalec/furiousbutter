fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'
{writeFile} = require 'fs'
try
    UglifyJS = require("uglify-js")
catch e
    if e.code == 'MODULE_NOT_FOUND'
        return
    throw e

build = (callback) ->
    ls = spawn 'ls', ['coffee']

    ls.stdout.on 'data', (data) ->
        for row in data.toString().split('\n')
            if not row.match /\.coffee/
                continue
            coffee = spawn 'coffee', ['-p', '-c', 'coffee/'+row]
            ((row) ->
                coffee.stdout.on 'data', (output) ->
                    filename = 'js/'+row.match(/\w*/)[0]
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

task 'watch', 'Watch source for changes', ->
    coffee = spawn 'coffee', ['-w', '-c', '-o', 'js', 'coffee']
    coffee.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    coffee.stdout.on 'data', (data) ->
        print data.toString()

task 'build', 'Build from src', ->
    build()
