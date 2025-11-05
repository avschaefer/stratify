import { Application } from "@hotwired/stimulus"
import PortfolioChartController from "./portfolio_chart_controller"

const application = Application.start()

application.register("portfolio-chart", PortfolioChartController)

application.debug = false
window.Stimulus = application

export { application }

