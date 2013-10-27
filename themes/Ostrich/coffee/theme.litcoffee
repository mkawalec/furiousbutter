The basic theme
===============

This is a basic theme for FuriousButter which primary purpose is to
serve as a foundation for building more complicated/complete
presentation solutions.

    class Ostrich extends Theme
        constructor: -> Ostrich.register @

        render_index: (ctx, callback) ->
            super ctx, (data) ->
                $('body').html data

        render_post: (post, list) ->
            console.log(post, list)

    ostrich = new Ostrich()

<!-- vim:set tw=72: -->
