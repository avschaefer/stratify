class DashboardController < ApplicationController
  include Exportable
  include ErrorHandler
  
  def index
    begin
      net_worth_service = NetWorthService.new(user: current_user)
      summary = net_worth_service.calculate
      
      @total_assets = summary[:total_assets]
      @total_liabilities = summary[:total_liabilities]
      @net_worth = summary[:net_worth]
      @monthly_savings = summary[:monthly_savings]
      @asset_allocation = summary[:asset_allocation]
      @monthly_trends = summary[:monthly_trends]
    rescue => e
      Rails.logger.error "Dashboard error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Set default values on error
      @total_assets = 0
      @total_liabilities = 0
      @net_worth = 0
      @monthly_savings = 0
      @asset_allocation = {}
      @monthly_trends = {}
      
      flash.now[:alert] = 'Unable to load dashboard data. Please try again.'
    end
    
    # Calculate trends (simplified - would come from historical data)
    @assets_trend = 12.0
    @liabilities_trend = -8.0
    @net_worth_trend = 18.0
  end
  
  def export
    # Placeholder for export functionality
  end
  
  def export_excel
    export_service = ExcelExportService.new(user: current_user)
    stream = export_service.generate
    
    send_data stream.read,
      filename: export_service.filename,
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  rescue => e
    handle_export_error(e)
  end
  
  def export_pdf
    export_service = PdfExportService.new(user: current_user)
    pdf_data = export_service.generate
    
    send_data pdf_data,
      filename: export_service.filename,
      type: "application/pdf",
      disposition: "attachment"
  rescue => e
    handle_export_error(e)
  end
end
