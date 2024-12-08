// constants
const PORT = 3000;

// dependencies
import express from 'express';
import bodyParser from 'body-parser';
import routes from './routes/routes.js';

// initiating the rest api
const app = express();

// middlewares
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' })); // Parse URL-encoded bodies with a 50MB limit

// initialize routes
app.use('/', routes);

// starting our server
app.listen(PORT, () => {
    console.log(`Server running on port: ${PORT}`);
})
