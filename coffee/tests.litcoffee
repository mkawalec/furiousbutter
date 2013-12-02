The test famework
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

                console.log _.first(_.values Router.routes)()
                _.keys(Router.routes).should.have.lengthOf 1
                _.first(_.values Router.routes)().should.eql 'I am the one'
