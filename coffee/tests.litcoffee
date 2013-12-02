The test framework
-----------------

    describe 'Router', ->

        describe 'route', ->
            it 'should add a new route correctly', (done) ->
                router = new Router()
                router.route 'test1', () -> done()

                _.some(_.keys(Router.routes), (key) ->
                    if key.toString() == (new RegExp 'test1').toString() 
                        return true
                    false).should.be.true

                _.first(_.values Router.routes)() 

            it 'should not add a route if the same route exists', ->
                router = new Router()
                Router.clear()

                router.route 'correct', () -> 'I am the one'
                router.route 'correct', () -> 'I am wrong'

                _.keys(Router.routes).should.have.lengthOf 1
                _.first(_.values Router.routes)().should.eql 'I am the one'

        describe 'clear', ->
            it 'should remove all routes', ->
                router = new Router()
                router.route 'test1', () -> done()
                Router.clear()

                _.keys(Router.routes).should.have.lengthOf 0

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



                





