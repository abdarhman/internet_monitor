/*!
 * Internet Monitor Score Keeper
 *
 * This plugin managing the downloading of data
 * required to calculate new IM scores
 * based on a set of indicators & weights.
 *
 * Current dependencies:
 * jquery.magnific-popup
 * jquery.ba-bbq
 *
 * Implementation notes:
 * - must be initialzied *before* weightSliders
 * - indicator info (id, adminName, etc.) is extracted from the slider elements
 * - the authority on current weight values is the bbq state, not the sliders themselves
 */

;( function ( $, undefined ) {
  var _defaults = {
    loaderCss: '.score-keeper-loader',
    dataPath: '/countries.json',
    maxScore: 10
  };

  var _options = { };

  var _countryData = null; //< raw data
  var _countries = []; //< by countryId

  var _indicators = []; //< by sourceId

  function _hashchange( e ) {
    $( '.score-pill' ).updateScore( );
  }

  $.scoreKeeper = {
    init: function( options ) {
      _options = $.extend( { }, _defaults, options );
      
      // extract previous state from sessionStorage, extend with url state
      if ( window.sessionStorage && window.JSON ) {
        var state = $.bbq.getState( );
        var sessionState = window.sessionStorage.getItem( 'bbqState' );
        if ( sessionState ) {
          state = $.extend( JSON.parse( sessionState ), state );
          $.bbq.pushState( state );
        }
        window.sessionStorage.setItem( 'bbqState', JSON.stringify( state ) );
      }

      // build an indexed list of indicators
      $( '.weight-slider' ).each( function( ) {
        var weightSlider = $( this );
        var sourceId = parseInt( weightSlider.data( 'sourceId' ) );
        var defaultWeight = parseFloat( weightSlider.data( 'defaultWeight' ) );

        _indicators[ sourceId ] = {
          adminName: weightSlider.data( 'adminName' ),
          defaultWeight: Math.abs( defaultWeight ),
          direction: defaultWeight
        };
      } );

      // load country data
      // show a modal popup indicator if it's taking too long
      var timeoutPopup = null;

      if ( !_countryData ) {
        $.ajax( {
          url: _options.dataPath,
          success: function( result ) {
            if ( timeoutPopup ) {
              clearTimeout( timeoutPopup );
              timeoutPopup = null;
            }

            _countryData = result;

            // build an indexed list of countries
            $.each( _countryData, function( ) {
              if ( this.country && $.isNumeric( this.country.id ) ) {
                _countries[ this.country.id ] = this.country;
              }
            } );

            $.magnificPopup.close( );
            $( window ).trigger( "hashchange" );
          },
          error: function( xhr ) {
          }
        } );

        timeoutPopup = setTimeout( function( ) {
          timeoutPopup = null;
          mfp = $.magnificPopup.open( { items: { src: _options.loaderCss, modal: true }, showCloseBtn: false } );
        }, 1000 );
      }

      $( window ).on( 'hashchange', _hashchange ); 
      
    },

    setWeight: function( adminName, value ) {
      var state = { };
      state[ adminName ] = value;
      $.bbq.pushState( state );
      if ( window.sessionStorage && window.JSON ) {
        window.sessionStorage.setItem( 'bbqState', JSON.stringify( $.bbq.getState( ) ) );
      }
    },

    calculateScore: function( country ) {
      var indicators = country.indicators;

      var sum = indicators.reduce( function( sum, indi, i ) {
        var indicator = _indicators[ indi.source_id ];
        var weight = $.bbq.getState( indicator.adminName, true );

        var output = sum + indi.normalized_value * ( weight || indicator.defaultWeight ) * indicator.direction;
        return output;
      }, 0.0);

      var average = sum / indicators.length;
      var score = average * _options.maxScore;
      return score;
    }
  };

  $.fn.updateScore = function( options ) {
    return this.each( function( ) {
      var scorePill = $( this ).filter( '.score-pill' );
      if ( scorePill.length > 0 ) {
        var countryId = scorePill.data( 'countryId' );
        var country = _countries[ countryId ];

        if ( country ) {
          scorePill.find( '.user-score' ).html( $.scoreKeeper.calculateScore( country ).toFixed( 2 ) ).addClass( 'updated' );
        }
      }
    } );

  };

} ) ( window.jQuery );
