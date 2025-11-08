// This file ensures custom controllers are registered
// stimulus-loading handles automatic loading of standard controllers

import { application } from "./application"
import PortfolioChartController from "./portfolio_chart_controller"
import ConfirmController from "./confirm_controller"

application.register("portfolio-chart", PortfolioChartController)
application.register("confirm", ConfirmController)

