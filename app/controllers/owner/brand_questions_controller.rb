class Owner::BrandQuestionsController < Owner::BaseController
  REFUSED = "Não foi possível salvar. Confira os campos destacados.".freeze
  NOTICE = "Marca atualizada.".freeze

  self.panel_section = :settings

  class_attribute :question_body, instance_writer: false

  def edit
    render frame(current_branding)
  end

  def update
    tenant = ActsAsTenant.current_tenant

    tenant.update_branding!(tenant_attrs: tenant_attrs, branding_attrs: branding_attrs, remove_logo: remove_logo?)
    redirect_to edit_path, notice: NOTICE
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = REFUSED
    render frame(tenant.branding_or_default), status: :unprocessable_entity
  end

  private

  def frame(branding)
    Views::Owner::BrandQuestions::Edit.new(
      tenant: ActsAsTenant.current_tenant,
      branding: branding,
      current_section: panel_section,
      body: question_body,
      back_to: owner_settings_path,
      url: submit_path,
      page_stylesheet: page_stylesheet
    )
  end

  def tenant_attrs = {}

  def branding_attrs = {}

  def remove_logo? = false

  def page_stylesheet = nil
end
