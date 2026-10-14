require "rails_helper"

RSpec.describe "PWA install decision", type: :system, js: true do
  it "maps the browser signals to action, instructions or hidden, with the invite reserved for phones" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"

    decisions = page.evaluate_async_script(<<~JS)
      const done = arguments[0]
      import("pwa_install").then(({ chooseInstallInvite }) => {
        done({
          androidWithPrompt: chooseInstallInvite(true, false, false, true),
          iphoneSafari: chooseInstallInvite(false, true, false, true),
          alreadyInstalled: chooseInstallInvite(false, false, true, true),
          desktopWithPrompt: chooseInstallInvite(true, false, false, false),
          androidBeforePrompt: chooseInstallInvite(false, false, false, true)
        })
      })
    JS

    expect(decisions).to eq(
      "androidWithPrompt" => "action",
      "iphoneSafari" => "instructions",
      "alreadyInstalled" => "hidden",
      "desktopWithPrompt" => "hidden",
      "androidBeforePrompt" => "hidden"
    )
  end
end
