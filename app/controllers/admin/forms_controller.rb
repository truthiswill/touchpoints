class Admin::FormsController < AdminController
  before_action :set_form, only: [:show, :edit, :update, :destroy]
  before_action :set_touchpoint, only: [:show, :edit]
  before_action :ensure_organization_manager

  def index
    @forms = Form.all
  end

  def show
    @touchpoint = @form.touchpoint
  end

  def new
    @form = Form.new
  end

  def edit
  end

  def create
    @form = Form.new(form_params)

    respond_to do |format|
      if @form.save
        format.html { redirect_to admin_form_path(@form), notice: 'Form was successfully created.' }
        format.json { render :show, status: :created, location: @form }
      else
        format.html { render :new }
        format.json { render json: @form.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @form.update(form_params)
        format.html {
          if @form.touchpoint
            redirect_to admin_touchpoint_form_path(@form.touchpoint, @form), notice: 'Form was successfully updated.'
          else
            redirect_to admin_form_path(@form), notice: 'Form was successfully updated.'
          end
        }
        format.json { render :show, status: :ok, location: @form }
      else
        format.html { render :edit }
        format.json { render json: @form.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @form.destroy
    respond_to do |format|
      format.html { redirect_to admin_forms_url, notice: 'Form was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_form
      @form = Form.find(params[:id])
    end

    def set_touchpoint
      @touchpoint = Touchpoint.find_by_id(params[:touchpoint_id])
    end

    def form_params
      params.require(:form).permit(
        :name,
        :kind,
        :character_limit,
        :notes,
        :status,
        :title,
        :instructions,
        :display_header_logo,
        :whitelist_url,
        :whitelist_test_url,
        :disclaimer_text,
        :question_text_01,
        :question_text_02,
        :question_text_03,
        :question_text_04,
        :question_text_05,
        :question_text_06,
        :question_text_07,
        :question_text_08,
        :question_text_09,
        :question_text_10,
        :question_text_11,
        :question_text_12,
        :question_text_13,
        :question_text_14,
        :question_text_15,
        :question_text_16,
        :question_text_17,
        :question_text_18,
        :question_text_19,
        :question_text_20
      )
    end
end
