import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default ({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const port = Number(env.PORT ?? '5173'); // Mặc định 5173 nếu không có env

  return defineConfig({
    plugins: [react()],
    server: {
      port,
      strictPort: false, // Cho phép tự đổi port nếu bị trùng
      proxy: {
        '/api': {
          target: 'http://localhost:5000',
          changeOrigin: true,
        },
      },
    },
    // QUAN TRỌNG: Đảm bảo không có dòng "base" lạ
    // base: './', <--- Nếu có dòng này thì xóa đi hoặc để '/'
  });
};