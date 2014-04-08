require 'spec_helper'

describe ( 'refinery/pages/home' ) {
  let ( :country ) { Country.find_by_iso3_code( 'IRN' ) }

  subject { rendered }

  context ( 'default view' ) {
    before {
      render
    }

    it {
      should_not have_css '.category-selector'
    }

    describe ( 'carousel' ) {
      it {
        should have_css 'div.carousel'
      }
      
      it {
        should have_css 'div.carousel > div a[href*="/about"]'
      }

      it {
        should have_css 'div.carousel > div a[href*="/map"]'
      }
    }

    it {
      should have_css 'h2', text: 'We monitor and report on...'
    }

    it ( 'should have tagline' ) {
      should have_css 'p.tagline', text: 'Evaluating'
    }

    it {
      should have_css 'li.category-block a[href*="/access"]'
      should have_css 'li.category-block h3', text: 'access'
      should have_css 'p', text: 'Who has Internet access'
    }

    it {
      should have_css 'li.category-block a[href*="/control"]'
      should have_css 'li.category-block h3', text: 'control'
    }

    it {
      should have_css 'li.category-block a[href*="/activity"]'
      should have_css 'li.category-block h3', text: 'activity'
    }

    it {
      should have_css 'li.category-block span', count: 3
    }

    it {
      should have_css 'section.twitter'
      should have_css 'section.twitter h1', text: 'Latest Tweets from'
    }

    it {
      should have_css '.twitter ul.tweets'
      should have_css 'ul.tweets li', count: 3
    }

    it {
      should have_css '.twitter span', text: 'on Twitter'
    }

    it {
      should have_css '.trending h2', text: 'Featured Countries'
    }

    it { 
      should have_css ".trending li a[data-country-id='#{country.id}']", text: country.name
    }

    it { 
      # score pills removed from home
      should_not have_css '.trending li .score-pill'
      should_not have_css ".trending .score-pill[data-country-id='#{country.id}']"
    }

    it {
      should_not have_css '.trending li .score-pill .user-score'
      should_not have_css '.trending li .score-pill .user-rank'
    }
  }
}
