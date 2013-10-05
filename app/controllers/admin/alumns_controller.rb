# encoding : utf-8
class Admin::AlumnsController < BeautifulController

  before_filter :load_alumn, :only => [:show, :edit, :update, :destroy]

  # Uncomment for check abilities with CanCan
  #authorize_resource

  def index
    session[:fields] ||= {}
    session[:fields][:alumn] ||= (Alumn.columns.map(&:name) - ["id"])[0..4]
    do_select_fields(:alumn)
    do_sort_and_paginate(:alumn)
    
    @q = Alumn.search(
      params[:q]
    )

    @alumn_scope = @q.result(
      :distinct => true
    ).sorting(
      params[:sorting]
    )
    
    @alumn_scope_for_scope = @alumn_scope.dup
    
    unless params[:scope].blank?
      @alumn_scope = @alumn_scope.send(params[:scope])
    end
    
    @alumns = @alumn_scope.paginate(
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
        render :json => @alumn_scope.all 
      }
      format.csv{
        require 'csv'
        csvstr = CSV.generate do |csv|
          csv << Alumn.attribute_names
          @alumn_scope.all.each{ |o|
            csv << Alumn.attribute_names.map{ |a| o[a] }
          }
        end 
        render :text => csvstr
      }
      format.xml{ 
        render :xml => @alumn_scope.all 
      }             
      format.pdf{
        pdfcontent = PdfReport.new.to_pdf(Alumn,@alumn_scope)
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
      format.json { render :json => @alumn }
    end
  end

  def new
    @alumn = Alumn.new

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @alumn }
    end
  end

  def edit
    
  end

  def create
    @alumn = Alumn.create(params[:alumn])

    respond_to do |format|
      if @alumn.save
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_alumns_path(:mass_inserting => true)
          else
            redirect_to admin_alumn_path(@alumn), :notice => t(:create_success, :model => "alumn")
          end
        }
        format.json { render :json => @alumn, :status => :created, :location => @alumn }
      else
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_alumns_path(:mass_inserting => true), :error => t(:error, "Error")
          else
            render :action => "new"
          end
        }
        format.json { render :json => @alumn.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @alumn.update_attributes(params[:alumn])
        format.html { redirect_to admin_alumn_path(@alumn), :notice => t(:update_success, :model => "alumn") }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @alumn.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @alumn.destroy

    respond_to do |format|
      format.html { redirect_to admin_alumns_url }
      format.json { head :ok }
    end
  end

  def batch
    attr_or_method, value = params[:actionprocess].split(".")

    @alumns = []    
    
    Alumn.transaction do
      if params[:checkallelt] == "all" then
        # Selected with filter and search
        do_sort_and_paginate(:alumn)

        @alumns = Alumn.search(
          params[:q]
        ).result(
          :distinct => true
        )
      else
        # Selected elements
        @alumns = Alumn.find(params[:ids].to_a)
      end

      @alumns.each{ |alumn|
        if not Alumn.columns_hash[attr_or_method].nil? and
               Alumn.columns_hash[attr_or_method].type == :boolean then
         alumn.update_attribute(attr_or_method, boolean(value))
         alumn.save
        else
          case attr_or_method
          # Set here your own batch processing
          # alumn.save
          when "destroy" then
            alumn.destroy
          end
        end
      }
    end
    
    redirect_to :back
  end

  def treeview

  end

  def treeview_update
    modelclass = Alumn
    foreignkey = :alumn_id

    render :nothing => true, :status => (update_treeview(modelclass, foreignkey) ? 200 : 500)
  end
  
  private 
  
  def load_alumn
    @alumn = Alumn.find(params[:id])
  end
end

