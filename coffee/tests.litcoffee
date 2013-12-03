The test framework
-----------------

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



                





