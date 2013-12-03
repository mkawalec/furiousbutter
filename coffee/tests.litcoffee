The test framework
-----------------

    describe 'Helpers', ->
        helpers = new Helpers

        describe 'extend', ->
            it 'should add functions as instance members', ->
                class Test extends Helpers

                test = new Test()
                test.extend {blah: -> 'hi'}
                _.keys(test).should.include 'blah'
                _.keys(Test).should.not.include 'blah'

        describe 'pull_params', ->
            it 'should deal with no-params routes', ->
                [addr, params] = helpers.pull_params 'i_am_a_route'
                addr.should.eql 'i_am_a_route'
                params.should.eql {}

            it 'should deal with no-route route', ->
                [addr, params] = helpers.pull_params '?param=value'
                addr.should.eql ''
                params.should.include {param: 'value'}

            it 'should accept multiple params', ->
                [addr, params] = helpers.pull_params 'hi?first=1&second=2'

                addr.should.eql 'hi'
                params.should.include {first: '1', second: '2'}

            it 'should parse empty route correctly', ->
                [addr, params] = helpers.pull_params ''

                addr.should.eql ''
                params.should.eql {}

        describe 'add_params', ->
            it 'should preserve a route with no added params', ->
                route = helpers.add_params 'hi?first=second'
                route.should.eql 'hi?first=second'

            it 'should add params to a no-params containing route', ->
                # One param
                route = helpers.add_params 'hi', {first: 'value'}
                route.should.eql 'hi?first=value'

                # Multiple params
                route = helpers.add_params 'hi', {first: 'value1', second: 'value2'}
                route.should.eql 'hi?first=value1&second=value2'

            it 'should merge with existing params', ->
                # One preexisting
                route = helpers.add_params 'hi?original=value', {new: 'new_val'}
                route.should.eql 'hi?original=value&new=new_val'

                # Multiple preexisting
                route = helpers.add_params 'hi?a=a&b=b', {c: 'c'}
                route.should.eql 'hi?a=a&b=b&c=c'

            it 'should work correctly with pull_params', ->
                [addr, params] = helpers.pull_params helpers.add_params(
                    'hi', {first: 1, second: 2})

                addr.should.eql 'hi'
                params.should.include {first: '1', second: '2'}

        describe 'expand_params', ->
            it 'should return a matcher and a params array', ->
                matched = helpers.expand_params ''
                _.keys(matched).should.include 'matcher'
                _.keys(matched).should.include 'params'

            it 'should expand simple params cases correctly', ->
                matched = helpers.expand_params '<first>'
                'hello'.match(matched.matcher).should.have.lengthOf 2

                matched = helpers.expand_params '<first>/<second>'
                'hi/hey'.match(matched.matcher).should.have.lengthOf 3

    describe 'Cache', ->
        cache = new Cache

        describe 'get', ->
            it 'should return nothing when the cache is empty', ->
                Cache.clear()

                cases = ['', 'a', 'c', undefined, 0, 1, true, false]
                _.each cases, (test_case) ->
                    if cache.get(test_case) != undefined
                        throw "Cache returns a value for #{test_case}"
                
        describe 'set', ->
            it 'should save simple values', ->
                cache.set 'key', 'value'
                cache.set 'key2', 2

                cache.get('key').should.equal 'value'
                cache.get('key2').should.equal 2

            it 'should have working timeout', (done) ->
                cache.set 'key3', 3, 0.01
                cache.get('key3').should.equal 3

                setTimeout( -> 
                    if cache.get('key3') != undefined
                        throw "Cache returns values for key3!"
                    done()
                , 11)

            it 'should persist objects correctly', ->
                cache.set 'obj', {param: 'value'}
                cache.get('obj').should.eql {param: 'value'}

            it 'should support non-string keys', ->
                cache.set {param: 'first'}, 1
                cache.set {param: 'second'}, 2
                cache.set /third/, 3

                cache.get({param: 'first'}).should.eql 1
                cache.get({param: 'second'}).should.eql 2
                cache.get(/third/).should.eql 3

        describe 'clear', ->
            it 'should clear both the persisted and non-persisted caches', ->
                Cache.clear()
                cache.set 'key', 'value'
                Cache.clear()
                _.keys(Cache.cache).should.not.include 'key'
                _.keys(JSON.parse(window.localStorage[Cache.storage_key] ? '{}')).\
                    should.not.include 'key'

        describe 'persist', ->
            it 'should persist the cache correctly', ->
                Cache.clear()
                cache.set 'new_key', 'new_value'
                cache.persist()

                parsed = JSON.parse(window.localStorage[Cache.storage_key])
                _.keys(parsed).should.include 'new_key'
                parsed['new_key'].payload.should.eql 'new_value'

        describe 'timeout', ->
            it 'should correctly say if a key has reached its timeout', (done) ->
                Cache.clear()
                cache.set 'key', 'value', 0.01
                cache.timeout('key').should.eql false

                setTimeout ->
                    cache.timeout('key').should.eql true
                    done()
                , 11

    describe 'CachedAjax', ->
        cached = new CachedAjax

        describe 'ajax', ->
            it 'should get local data correctly (callback)', (done) ->
                cached.ajax {
                    url: 'README.md'
                    success: (data) ->
                        data.should.include 'CachedAjax'
                        done()
                    error: ->
                        throw "The file should be available"
                        done()
                }

            it 'should get local data correctly (promise)', (done) ->
                req = cached.ajax {url: 'README.md'}
                req.then( (data) ->
                    data.should.include 'CachedAjax'
                    done()
                ).catch (e) ->
                    throw "The file should be available"
                    done()

            it 'should fail on invalid address (callback)', (done) ->
                cached.ajax {
                    url: 'invalid'
                    success: ->
                        throw "This file should not be accessible"
                        done()
                    error: ->
                        done()
                }

            it 'should fail on invalid address (promise)', (done) ->
                req = cached.ajax {url: 'invalid'}
                req.then( ->
                    throw "This file should not be accessible"
                    done()
                ).catch (e) ->
                    done()


    describe 'Router', ->
        describe 'route', ->
            it 'should add a new route correctly', (done) ->
                router = new Router()
                router.route 'test1', () -> done()

                _.some(Router.routes, (value) ->
                    if value.route.toString() == (new RegExp 'test1').toString() 
                        return true
                    false).should.be.true

                _.first(Router.routes).callback() 

            it 'should not add a route if the same route exists', ->
                router = new Router()
                Router.clear()

                router.route 'correct',  -> 'I am the one'
                router.route 'correct',  -> 'I am wrong'

                Router.routes.should.have.lengthOf 1
                _.first(Router.routes).callback().should.eql 'I am the one'

            it 'should support regex routes', (done) ->
                router = new Router()
                Router.clear()

                counter = 0
                router.route 'a?bc', () ->
                    if counter > 0
                        @route.should.eql 'abc'
                        done()
                    else
                        @route.should.eql 'bc'

                    counter += 1

                router.goto 'bc'
                router.hashchange()
                router.goto 'abc'
                router.hashchange()

            it 'should support inline parameters', (done) ->
                router = new Router()
                Router.clear()

                router.route 'b(a|m)/<param1>/(c|d)/<param2>', (params) ->
                    params.should.include {param1: 'value1'}
                    params.should.include {param2: 'value2'}
                    done()

                router.goto 'ba/value1/c/value2'
                router.hashchange()

            it 'should not add a route if the only difference 
                between old and new routes is parameter name', ->
                    router = new Router()
                    Router.clear()

                    router.route '<param1>', -> 'Old'
                    router.route '<param2>', -> 'new'

                    Router.routes.should.have.lengthOf 1
                    _.first(Router.routes).callback().should.eql 'Old'

        describe 'clear', ->
            it 'should remove all routes', ->
                router = new Router()
                router.route 'test1', () -> done()
                Router.clear()

                Router.routes.should.have.lengthOf 0

        describe 'goto', ->
            set_router = (route, fn) ->
                Router.clear()

                router = new Router()
                router.route 'test1', ( -> )
                return router

            it 'should set a simple route', ->
                router = set_router()
                router.goto 'test1'
                window.location.hash.should.include 'test1'

            it 'should pull params from an Object', ->
                router = set_router()
                router.goto 'test1', {one: 'two'}
                window.location.hash.should.include 'one=two'

            it 'should combine Object and address params', ->
                router = set_router()
                router.goto 'test1?addr=one', {obj: 'two'}

                window.location.hash.should.include 'addr=one'
                window.location.hash.should.include 'obj=two'
                window.location.hash.should.include '&'

            it 'should accept an Array', ->
                router = set_router()
                router.goto 'test1', ['first', 'second']

                window.location.hash.should.include '0=first'
                window.location.hash.should.include '1=second'

            it 'should accept multiple params', ->
                router = set_router()
                router.goto 'test1', 'first', 'second'

                window.location.hash.should.include 'first=first'
                window.location.hash.should.include 'second=second'

                router.goto 'test1', {dict: 'param'}, 'second'
                window.location.hash.should.include 'second=second'
                window.location.hash.should.include 'dict=param'

                router.goto 'test1', {first: 'first'}, {second: 'second'}
                window.location.hash.should.include 'first=first'
                window.location.hash.should.include 'second=second'

            it 'should set a non-existent route', ->
                router = set_router()
                router.goto 'wrong_one'
                window.location.hash.should.include 'wrong_one'
