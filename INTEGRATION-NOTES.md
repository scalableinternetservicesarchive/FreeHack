The client-side implements caching through the use of Redux. Redux is
essentially a state tree that serves as a single source of data for the entire
client-side application.

It's extremely important that the data returned from the server be denormalized
as possible, as the state tree (aka the store) is optimized for "flat" data.

Basically, avoid nesting while constructing JSONs on the server, if possible!

This is how I've organized the store client-side; I'm writing it out here
since the front-end code does not make this evident unless you trace through
the Redux logic:

Three types of entity schemas on the front-end, corresponding to:
 1. many-to-many => join table
 2. one-to-one => id reference
 3. one-to-many => xByY

Also note: If one needs to poll and cache new results, we also have the fields "fetching",
"didinvalidate", etc. stored appropariately.

    store: {
        auth: {
            // Auth header info, returned by devise-token-auth
        },
        entities: {
            users: {
                byId: {
                    id1: {
                        handle: // string,
                        bio: // string,
                        tagline: // string
                    }
                },
                // Preserve order returned by API
                allIds: [id1]
            },
            connections: {
                byId: {
                    id1: {
                        follower: // string => user id,
                        following: // string => user id
                    }
                },
                // Preserve order returned by API
                allIds: [id1]
            },
            tweetsByUser: {
                // Allows easy access to finding tweets by user
                byId: {
                    userId: {
                        tweets: // an array of tweet ids,
                        fetching: // boolean,
                        didInvalidate: // boolean
                    }
                },
                // Preserve order returned by API
                allIds: [id1]
            }
            tweets: {
                byId: {
                    id1: {
                        body: // emoji text representation,
                        user: // string,
                        createdAt: // timestamp
                    }
                },
                // Preserve order returned by API
                allIds:[id1]
            },
            repliesByTweet: {
                byId: {
                    id1: {
                        replies: // an array of tweet ids,
                        fetching: // refreshing from server,
                        didInvalidate: // needs to be refreshed
                    }
                },
                // Preserve order returned by API
                allIds: [id1]
            },
            replies: {
                byId: {
                    id1: {
                        ogTweet: // string,
                        replyTweet: // string
                    }
                },
                // Preserve order returned by API
                allIds: [id1]
            }
        },
        draftEntities: {
            // A user is manipulating, but has not been committed to server.
            // OR app is waiting for server response to committing manipulation.
            // OR non-success returned by server (timeout, error).
            tweets: {
                byId: {
                    id1: {
                        // States relevant to manipulation
                    }
                },
                allIds: [id1]
            },
            connections: {
                byId: {
                    id1: {
                        // States relevant to manipulation
                    }
                },
                allIds: [id1]
            },
            user: {
                // Note: a user can only edit their own bio and tagline,
                // so this will only ever have one entry
                byId: {
                    id1: {
                        // States relevant to manipulation
                    }
                },
                allIds: [id1]
            },
        },
        uiData: {
            // Filters, non-server-backed data and the likes
            searchBar: {
                terms: [
                    term: // string rep,
                    termType: // hashtag, mention, string
                ],
                active: // user is currently typing
            },
            // Like this is like a "visibility" filter
            activeTweet: {
                // simply a pointer
            }
        }
    }

With this front-end schema, we need:
 * All requests that successfully manipulate an entity should return the new representation of that entity.
 * All denied requests should return a standardized error JSON.  	
~~~~
{
    type: "error",
    msg: "reason here"
}
~~~~
 * Every entity that can be "listed" (tweets, connections, profiles) should allow polling for the X most recent,
    with an optional "bookmark" id that says search after this point.
~~~~
{
    bookmark: // an id for last returned result, search past this point
}
~~~~
 * Tweets should be searchable by the following JSON request:
~~~~
{
    terms: [
        term: // a string representation of the term
        termType: // whether the term is a hashtag, mention, or string
    ],
    // Obviously, we can pass the bookmark as well:
    bookmark: // same as #3
}
~~~~