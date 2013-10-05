# encoding : utf-8
class Admin::CoursesController < BeautifulController

  before_filter :load_course, :only => [:show, :edit, :update, :destroy]

  # Uncomment for check abilities with CanCan
  #authorize_resource

  def index
    session[:fields] ||= {}
    session[:fields][:course] ||= (Course.columns.map(&:name) - ["id"])[0..4]
    do_select_fields(:course)
    do_sort_and_paginate(:course)
    
    @q = Course.search(
      params[:q]
    )

    @course_scope = @q.result(
      :distinct => true
    ).sorting(
      params[:sorting]
    )
    
    @course_scope_for_scope = @course_scope.dup
    
    unless params[:scope].blank?
      @course_scope = @course_scope.send(params[:scope])
    end
    
    @courses = @course_scope.paginate(
      :page => params[:page],
      :per_page => 20
    ).all

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json{
        render :json => @course_scope.all 
      }
      format.csv{
        require 'csv'
        csvstr = CSV.generate do |csv|
          csv << Course.attribute_names
          @course_scope.all.each{ |o|
            csv << Course.attribute_names.map{ |a| o[a] }
          }
        end 
        render :text => csvstr
      }
      format.xml{ 
        render :xml => @course_scope.all 
      }             
      format.pdf{
        pdfcontent = PdfReport.new.to_pdf(Course,@course_scope)
        send_data pdfcontent
      }
    end
  end

  def show
    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @course }
    end
  end

  def new
    @course = Course.new

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @course }
    end
  end

  def edit
    
  end

  def create
    @course = Course.create(params[:course])

    respond_to do |format|
      if @course.save
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_courses_path(:mass_inserting => true)
          else
            redirect_to admin_course_path(@course), :notice => t(:create_success, :model => "course")
          end
        }
        format.json { render :json => @course, :status => :created, :location => @course }
      else
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_courses_path(:mass_inserting => true), :error => t(:error, "Error")
          else
            render :action => "new"
          end
        }
        format.json { render :json => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @course.update_attributes(params[:course])
        format.html { redirect_to admin_course_path(@course), :notice => t(:update_success, :model => "course") }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @course.destroy

    respond_to do |format|
      format.html { redirect_to admin_courses_url }
      format.json { head :ok }
    end
  end

  def batch
    attr_or_method, value = params[:actionprocess].split(".")

    @courses = []    
    
    Course.transaction do
      if params[:checkallelt] == "all" then
        # Selected with filter and search
        do_sort_and_paginate(:course)

        @courses = Course.search(
          params[:q]
        ).result(
          :distinct => true
        )
      else
        # Selected elements
        @courses = Course.find(params[:ids].to_a)
      end

      @courses.each{ |course|
        if not Course.columns_hash[attr_or_method].nil? and
               Course.columns_hash[attr_or_method].type == :boolean then
         course.update_attribute(attr_or_method, boolean(value))
         course.save
        else
          case attr_or_method
          # Set here your own batch processing
          # course.save
          when "destroy" then
            course.destroy
          end
        end
      }
    end
    
    redirect_to :back
  end

  def treeview

  end

  def treeview_update
    modelclass = Course
    foreignkey = :course_id

    render :nothing => true, :status => (update_treeview(modelclass, foreignkey) ? 200 : 500)
  end
  
  private 
  
  def load_course
    @course = Course.find(params[:id])
  end
end

