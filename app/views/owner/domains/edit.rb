class Views::Owner::Domains::Edit < Views::Base
  FIELD_CLASS = "mt-1 w-full rounded-md border border-gray-300 px-3 py-2"

  def initialize(tenant:)
    @tenant = tenant
  end

  def view_template
    render Views::Layouts::Application.new(title: "Domínio · Zubio", branding: @tenant.branding_or_default) do
      div(class: "mx-auto mt-16 w-full max-w-sm") do
        h1(class: "mb-6 text-center text-2xl font-semibold") { "Domínio próprio" }
        render_verification_instructions if pending_verification?
        render_active_notice if @tenant.custom_domain_verified_at.present?
        form_with(url: owner_domain_path, method: :patch, class: "space-y-4") do |form|
          render_domain_field(form)
          render_remove_domain_field if @tenant.custom_domain.present?
          form.submit "Salvar", class: "w-full rounded-md bg-brand-600 px-4 py-2 font-medium text-on-brand"
        end
      end
    end
  end

  private

  def pending_verification?
    @tenant.custom_domain.present? && @tenant.custom_domain_verified_at.blank?
  end

  def render_domain_field(form)
    div do
      form.label :custom_domain, "Domínio (ex: barbeariadoze.com.br)", class: "block text-sm font-medium"
      form.text_field :custom_domain, name: "domain[custom_domain]", value: @tenant.custom_domain, class: FIELD_CLASS
      render_errors(@tenant.errors[:custom_domain])
    end
  end

  def render_verification_instructions
    div(class: "mb-4 rounded-md border border-gray-300 bg-gray-50 p-4 text-sm") do
      p(class: "font-medium") { "Pendente de verificação — adicione este registro TXT no DNS do seu domínio:" }
      dl(class: "mt-2 space-y-1") do
        dt(class: "font-mono text-xs text-gray-500") { "Nome" }
        dd(class: "font-mono text-xs") { @tenant.custom_domain_verification_txt_name }
        dt(class: "font-mono text-xs text-gray-500") { "Valor" }
        dd(class: "font-mono text-xs") { @tenant.custom_domain_verification_txt_value }
      end
      p(class: "mt-3") { "Depois, aponte um registro CNAME de #{@tenant.custom_domain} para #{Tenant::CUSTOM_DOMAIN_FALLBACK_TARGET}." }
    end
  end

  def render_active_notice
    p(class: "mb-4 rounded-md bg-green-50 p-3 text-sm text-green-800") { "Domínio ativo." }
  end

  def render_remove_domain_field
    div(class: "mt-2 flex items-center gap-2") do
      input(type: "hidden", name: "domain[remove_domain]", value: "0")
      input(type: "checkbox", name: "domain[remove_domain]", id: "domain_remove_domain", value: "1", class: "rounded border-gray-300")
      label(for: "domain_remove_domain", class: "text-sm") { "Remover domínio próprio" }
    end
  end

  def render_errors(messages)
    return if messages.empty?

    p(class: "mt-1 text-sm text-red-700") { messages.join(", ") }
  end
end
