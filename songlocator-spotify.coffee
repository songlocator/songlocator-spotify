((root, factory) ->
  if typeof exports == 'object'
    SongLocator =  require 'songlocator-base'
    module.exports = factory(SongLocator)
  else if typeof define == 'function' and define.amd
    define (require) ->
      SongLocator =  require 'songlocator-base'
      root.SongLocator.Spotify = factory(SongLocator)
  else
    root.SongLocator.Spotify = factory(SongLocator)

) this, ({BaseResolver, extend}) ->

  class Resolver extends BaseResolver
    name: 'spotify'

    options: extend BaseResolver::options, {resolveImageURL: true}

    parseImageURL: (data) ->
      data = (/<img[^>]+>/.exec data)[0]
      data = (/src="([^\"]+)"/.exec data)[1]

    resolveImageURL: (id, callback) ->
      this.request
        method: 'GET'
        url: "http://open.spotify.com/track/#{id.split(':')[2]}"
        rawResponse: true
        callback: (error, data) =>
          callback(undefined) if error or not data
          callback(this.parseImageURL(data))

    search: (qid, query) ->
      this.request
        method: 'GET'
        url: 'http://ws.spotify.com/search/1/track.json'
        params: {q: query}
        callback: (error, data) =>
          return if error?
          return if data.tracks.length == 0

          tracks = data.tracks.slice(0, this.options.searchMaxResults)
          imagesResolved = 0

          results = for r in tracks
            do (r) =>
              result =
                title: r.name
                artist: (a.name for a in r.artists).join(', ')
                album: r.album?.name?

                source: this.name
                id: r.href

                linkURL: "http://open.spotify.com/track/#{r.href.split(':')[2]}"
                imageURL: undefined # TODO: resolve via linkURL
                audioURL: undefined
                audioPreviewURL: undefined

                mimetype: undefined
                duration: r.length

              if this.options.resolveImageURL
                this.resolveImageURL result.id, (imageURL) =>
                  result.imageURL = imageURL
                  imagesResolved = imagesResolved + 1
                  if imagesResolved == tracks.length
                    this.results(qid, results)

              result

          unless this.options.resolveImageURL
            this.results(qid, results)

  {Resolver}
