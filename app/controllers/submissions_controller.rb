class SubmissionsController < ApplicationController
  protect_from_forgery only: []
  before_action :set_form, only: [:new, :create]

  layout 'public', only: :new

  def new
    unless @form.deployable_form?
      redirect_to index_path, alert: "Form is not yet deployable."
    end
    @form.update_attribute(:survey_form_activations, @form.survey_form_activations += 1)
    @submission = Submission.new
    # set location code in the form based on `?location_code=`
    @submission.location_code = params[:location_code]
  end

  def create
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'

    # Prevent the Submission if this is a published Form and if:
    if @form &&
      request.referer &&
      # is not from the Form's whitelist URL
      (@form.whitelist_url.present? ? !request.referer.start_with?(@form.whitelist_url) : true) &&
      # is not from the Form's test whitelist URL
      (@form.whitelist_test_url.present? ? !request.referer.start_with?(@form.whitelist_test_url) : true) &&
      # is not from the Touchpoints app
      !request.referer.start_with?(root_url) &&
      # is not from the Organization URL
      !request.referer.start_with?(@form.organization.url)

      render json: {
        status: :unprocessable_entity,
        messages: {"submission": ["request made from non-authorized host"] }
        }, status: :unprocessable_entity and return
    end

    @submission = Submission.new(submission_params)
    @submission.form = @form
    @submission.user_agent = request.user_agent
    @submission.referer = submission_params[:referer]
    @submission.page = submission_params[:page]
    @submission.ip_address = request.remote_ip

    create_in_local_database(@submission)
  end


  private

    def create_in_local_database(submission)
      respond_to do |format|
        if submission.save
          format.html {
            redirect_to submit_touchpoint_path(submission.form.short_uuid), notice: 'Thank You. Response was submitted successfully.' }
          format.json {
            render json: {
              submission: {
                id: submission.id,
                first_name: submission.answer_01,
                last_name: submission.answer_02,
                email: submission.answer_03,
                phone_number: submission.answer_04,
                form: {
                  id: submission.form.uuid,
                  name: submission.form.name,
                  organization_name: submission.organization_name
                }
              }
            },
            status: :created
          }
        else
          format.html {
          }
          format.json {
            render json: {
              status: :unprocessable_entity,
              messages: submission.errors
            }, status: :unprocessable_entity
          }
        end
      end
    end

    def set_form
      if params[:form] # coming from /touchpoints/:id/submit
        @short_uuid = (params[:id].to_s.length == 8) ?
          params[:id] :
          Form.find_by_id(params[:id]).short_uuid
      elsif params[:form_id]
        @short_uuid = (params[:form_id].to_s.length == 8) ?
          params[:form_id] :
          (Form.find_by_uuid(params[:form_id]) || Form.find_by_id(params[:form_id]).short_uuid)
      elsif params[:touchpoint_id]
        @short_uuid = (params[:touchpoint_id].to_s.length == 8) ?
          params[:touchpoint_id] :
          (Form.find_by_legacy_touchpoints_uuid(params[:touchpoint_id]) || Form.find_by_legacy_touchpoints_id(params[:touchpoint_id]).short_uuid || Form.find_by_uuid(params[:form_id]) || Form.find_by_id(params[:form_id]).short_uuid)
      end

      @form = FormCache.fetch(@short_uuid)
      raise ActiveRecord::RecordNotFound, "no form with ID of #{@short_uuid}" unless @form.present?
    end

    def submission_params
      permitted_fields = @form.questions.collect(&:answer_field)
      permitted_fields << [:language, :location_code, :referer, :page]
      params.require(:submission).permit(permitted_fields)
    end
end
