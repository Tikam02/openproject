#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe 'OAuth applications management', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
    visit oauth_applications_path
  end

  it 'can create, update, show and delete applications' do
    # Initially empty
    expect(page).to have_selector('.generic-table--empty-row', text: 'There is currently nothing to display')

    # Create application
    find('.button', text: 'Add').click

    SeleniumHubWaiter.wait
    fill_in 'application_name', with: 'My API application'
    # Fill invalid redirect_uri
    fill_in 'application_redirect_uri', with: "not a url!"
    click_on 'Create'

    expect(page).to have_selector('.errorExplanation', text: 'Redirect URI must be an absolute URI.')

    SeleniumHubWaiter.wait
    fill_in('application_redirect_uri', with: "")
    # Fill rediret_uri which does not provide a Secure Context
    fill_in 'application_redirect_uri', with: "http://example.org"
    click_on 'Create'

    expect(page).to have_selector('.errorExplanation', text: 'Redirect URI is not providing a "Secure Context"')

    # Can create localhost without https (https://community.openproject.com/wp/34025)
    SeleniumHubWaiter.wait
    fill_in 'application_redirect_uri', with: "urn:ietf:wg:oauth:2.0:oob\nhttp://localhost/my/callback"
    click_on 'Create'

    expect(page).to have_selector('.flash.notice', text: 'Successful creation.')

    expect(page).to have_selector('.attributes-key-value--key', text: 'Client ID')
    expect(page).to have_selector('.attributes-key-value--value', text: "urn:ietf:wg:oauth:2.0:oob\nhttp://localhost/my/callback")

    # Should print secret on initial visit
    expect(page).to have_selector('.attributes-key-value--key', text: 'Client secret')
    expect(page.first('.attributes-key-value--value code').text).to match /\w+/

    # Edit again
    SeleniumHubWaiter.wait
    click_on 'Edit'

    SeleniumHubWaiter.wait
    fill_in 'application_redirect_uri', with: "urn:ietf:wg:oauth:2.0:oob"
    click_on 'Save'

    # Show application
    SeleniumHubWaiter.wait
    find('td a', text: 'My API application').click

    expect(page).to have_no_selector('.attributes-key-value--key', text: 'Client secret')
    expect(page).to have_no_selector('.attributes-key-value--value code')
    expect(page).to have_selector('.attributes-key-value--key', text: 'Client ID')
    expect(page).to have_selector('.attributes-key-value--value', text: "urn:ietf:wg:oauth:2.0:oob")

    SeleniumHubWaiter.wait
    click_on 'Delete'
    page.driver.browser.switch_to.alert.accept

    # Table is empty again
    expect(page).to have_selector('.generic-table--empty-row', text: 'There is currently nothing to display')
  end
end
