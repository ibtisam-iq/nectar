const express = require('express') // Import express  
const app = express() // function to create an express app
const port= process.env.PORT || 4000
// The server listens on the port defined by process.env.PORT or defaults to 4000 if not set.
app.listen(port, ()  => { // it expects port number and a callback function
        console.log(`Example app listening at http://localhost:${port}`)
})


// this is the frontend being served from the public folder
app.get('/', (req, res) => {
        res.send('Hello ibtisam, my love')
})
