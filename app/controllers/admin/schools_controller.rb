# encoding : utf-8
class Admin::SchoolsController < BeautifulController

  before_filter :load_school, :only => [:show, :edit, :update, :destroy]

  # Uncomment for check abilities with CanCan
  #authorize_resource

  def index
    session[:fields] ||= {}
    session[:fields][:school] ||= (School.columns.map(&:name) - ["id"])[0..4]
    do_select_fields(:school)
    do_sort_and_paginate(:school)
    
    @q = School.search(
      params[:q]
    )

    @school_scope = @q.result(
      :distinct => true
    ).sorting(
      params[:sorting]
    )
    
    @school_scope_for_scope = @school_scope.dup
    
    unless params[:scope].blank?
      @school_scope = @school_scope.send(params[:scope])
    end
    
    @schools = @school_scope.paginate(
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
        render :json => @school_scope.all 
      }
      format.csv{
        require 'csv'
        csvstr = CSV.generate do |csv|
          csv << School.attribute_names
          @school_scope.all.each{ |o|
            csv << School.attribute_names.map{ |a| o[a] }
          }
        end 
        render :text => csvstr
      }
      format.xml{ 
        render :xml => @school_scope.all 
      }             
      format.pdf{
        pdfcontent = PdfReport.new.to_pdf(School,@school_scope)
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
      format.json { render :json => @school }
    end
  end

  def new
    @school = School.new

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @school }
    end
  end

  def edit
    
  end

  def create
    @school = School.create(params[:school])

    respond_to do |format|
      if @school.save
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_schools_path(:mass_inserting => true)
          else
            redirect_to admin_school_path(@school), :notice => t(:create_success, :model => "school")
          end
        }
        format.json { render :json => @school, :status => :created, :location => @school }
      else
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_schools_path(:mass_inserting => true), :error => t(:error, "Error")
          else
            render :action => "new"
          end
        }
        format.json { render :json => @school.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @school.update_attributes(params[:school])
        format.html { redirect_to admin_school_path(@school), :notice => t(:update_success, :model => "school") }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @school.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @school.destroy

    respond_to do |format|
      format.html { redirect_to admin_schools_url }
      format.json { head :ok }
    end
  end

  def batch
    attr_or_method, value = params[:actionprocess].split(".")

    @schools = []    
    
    School.transaction do
      if params[:checkallelt] == "all" then
        # Selected with filter and search
        do_sort_and_paginate(:school)

        @schools = School.search(
          params[:q]
        ).result(
          :distinct => true
        )
      else
        # Selected elements
        @schools = School.find(params[:ids].to_a)
      end

      @schools.each{ |school|
        if not School.columns_hash[attr_or_method].nil? and
               School.columns_hash[attr_or_method].type == :boolean then
         school.update_attribute(attr_or_method, boolean(value))
         school.save
        else
          case attr_or_method
          # Set here your own batch processing
          # school.save
          when "destroy" then
            school.destroy
          end
        end
      }
    end
    
    redirect_to :back
  end

  def treeview

  end

  def treeview_update
    modelclass = School
    foreignkey = :school_id

    render :nothing => true, :status => (update_treeview(modelclass, foreignkey) ? 200 : 500)
  end
  
  private 
  
  def load_school
    @school = School.find(params[:id])
  end
end

