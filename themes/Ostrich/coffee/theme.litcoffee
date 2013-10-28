The basic theme
===============

This is a basic theme for FuriousButter which primary purpose is to
serve as a foundation for building more complicated/complete
presentation solutions.

    class Ostrich extends Theme

Each theme needs to notify the theme controller of its existence.

        constructor: -> Ostrich.register @

The following is called when **Blog** wants the theme to render an
index. The *super* method contains all the logic so we just have to pass
a current context and a callback to it.

        render_index: (ctx, callback) ->
            super ctx, (data) ->

Populate body with the theme data.

                $('body').html data

When the blog wants to render a post it calls the following. Currently
there is no way to if an index of a post page is requested.

        render_post: (post, list) ->
            console.log(post, list)

Create new theme instance

    ostrich = new Ostrich()

<!-- vim:set tw=72: -->
