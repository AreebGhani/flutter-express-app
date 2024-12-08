import express from "express";
import upload from "../multer.js";

// initialize router
const router = express.Router();

// routes
// get
router.get("/", async (req, res) => {
  res.send("Your server is ready!");
});

// post
router.post("/", upload.array("images", 3), async (req, res) => {
  console.log("\n\nBody: ", req.body);
  console.log("Files: ", req.files);
  res
    .status(200)
    .send(
      `Uploaded ${req.body?.images?.length ?? 0} string urls and ${
        req.files?.length ?? 0
      } binary files`
    );
});

// patch
router.patch("/", async (req, res) => {});

// put
router.put("/", async (req, res) => {});

// delete
router.delete("/", async (req, res) => {});

export default router;
