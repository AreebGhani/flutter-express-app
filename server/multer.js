import multer from 'multer';

const upload = multer({
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB limit
  storage: multer.memoryStorage(), // Store the files in memory
});

export default upload;
