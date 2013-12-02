The test famework
-----------------

    describe 'Router', ->
        describe 'route', ->
            it 'should add a new route correctly', ->
                router = new Router()
                router.route 'test1', () -> 'I am the one'

                _.some(_.keys(Router.routes), (key) ->
                    if key.toString() == (new RegExp 'test1').toString() 
                        return true
                    false).should.be.true
