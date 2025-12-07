import { DataSource } from 'typeorm';
export declare class LogisticsService {
    private dataSource;
    constructor(dataSource: DataSource);
    getRestaurants(): Promise<any>;
    getFoodsByRestaurant(id: number): Promise<any>;
    createFullOrder(data: any): Promise<any>;
    previewOrder(data: any): Promise<any>;
    getAllOrders(customerId: number): Promise<any>;
    getTrendingFoods(minQuantity: number): Promise<any>;
    updateOrderInfo(orderId: number, address: string): Promise<{
        message: string;
    }>;
    deleteOrder(orderId: number): Promise<{
        message: string;
    }>;
}
