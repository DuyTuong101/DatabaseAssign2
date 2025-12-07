import { LogisticsService } from './logistics.service';
export declare class LogisticsController {
    private srv;
    constructor(srv: LogisticsService);
    getRestaurants(): Promise<any>;
    getFoods(id: string): Promise<any>;
    previewOrder(body: any): Promise<any>;
    createOrder(body: any): Promise<any>;
    getAllOrders(id: string): any[] | Promise<any>;
    getTrending(min?: string): Promise<any>;
    updateOrderInfo(id: string, body: {
        address: string;
    }): Promise<{
        message: string;
    }>;
    deleteOrder(id: string): Promise<{
        message: string;
    }>;
}
