import { Controller, Get, Post, Put, Delete, Body, Param, Query } from '@nestjs/common';
import { LogisticsService } from './logistics.service';

@Controller('logistics')
export class LogisticsController {
  constructor(private srv: LogisticsService) {}

  // 1. Helper
  @Get('restaurants')
  getRestaurants() { return this.srv.getRestaurants(); }

  @Get('restaurants/:id/foods')
  getFoods(@Param('id') id: string) { return this.srv.getFoodsByRestaurant(+id); }

  // 2. Order Flow
  @Post('orders/preview') // [MỚI] API Tính tiền thử
  previewOrder(@Body() body: any) { return this.srv.previewOrder(body); }

  @Post('orders')
  createOrder(@Body() body: any) { return this.srv.createFullOrder(body); }

@Get('orders')
  getAllOrders(@Query('customerId') id: string) {
    // Nếu không có ID thì báo lỗi hoặc trả rỗng tùy bạn
    if (!id) return []; 
    return this.srv.getAllOrders(+id);
  }

  @Get('trending')
  getTrending(@Query('min') min?: string) { return this.srv.getTrendingFoods(Number(min) || 1); }

@Put('orders/:id/info')
  updateOrderInfo(
    @Param('id') id: string, 
    @Body() body: { address: string }
  ) {
    return this.srv.updateOrderInfo(+id, body.address);
  }

  @Delete('orders/:id')
  deleteOrder(@Param('id') id: string) { return this.srv.deleteOrder(+id); }
}