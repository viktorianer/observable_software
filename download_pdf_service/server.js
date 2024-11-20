const express = require('express');
const { chromium } = require('playwright');
const fs = require('fs').promises;
const app = express();
const port = 3004;

app.use(express.json());

app.post('/download_pdf', async (req, res) => {
  if (!req.body || !req.body.pattern) {
    return res.status(400).json({ error: 'Pattern is required', body: req.body });
  }

  const browserOptions = {
    wsEndpoint: 'ws://chrome:3000/playwright/chromium?token=6R0W53R135510'
  };

  try {
    // Create temp file for the JSON data
    const jsonTempPath = '/tmp/temp.fcjson';
    await fs.writeFile(jsonTempPath, JSON.stringify(req.body.pattern));

    const browser = await chromium.connect(browserOptions.wsEndpoint);
    const context = await browser.newContext({
      acceptDownloads: true,
      viewport: { width: 1200, height: 800 }
    });

    const page = await context.newPage();
    
    console.log('Navigating to https://flosscross.com/designer/');
    await page.goto('https://flosscross.com/designer/');
    await page.waitForLoadState('networkidle');

    console.log('Setting input files');
    const fileInput = await page.locator('input[type="file"]').first();
    await fileInput.setInputFiles(jsonTempPath);
    await page.waitForLoadState('networkidle');

    console.log('Navigating to https://flosscross.com/designer/slot/1/pdf');
    await page.goto('https://flosscross.com/designer/slot/1/pdf');
    await page.waitForLoadState('networkidle');

    const width = req.body.pattern.model.images[0].width;
    const height = req.body.pattern.model.images[0].height;
    await page.getByLabel('Image caption').fill(`Design size: ${width} x ${height} stitches`);
    await page.getByLabel('Description').first().fill('Pixel Art Mini Cross Stitch Pattern\n\nAvailable from https://minicrossstitching.etsy.com');
    await page.getByLabel('Subtitle').fill('Cross stitch chart');
    await page.getByLabel('Header text').fill('Cross stitch chart');
    await page.getByLabel('Footer text').fill('© 2024 Mini Cross Stitching');
    await page.getByLabel('Title').nth(2).fill('Floss list for stitches');

    console.log('Clicking Save To PDF');
    await page.waitForSelector('button:has-text("Save To PDF")');
    await page.click('button:has-text("Save To PDF")');

    console.log('Clicking OK');
    await page.waitForSelector('.q-btn__content:has-text("OK")');
    const downloadPromise = page.waitForEvent('download');
    await page.click('.q-btn__content:has-text("OK")');

    const download = await downloadPromise;
    console.log('Saving to PDF');
    const pdfTempPath = '/tmp/temp.pdf';
    await download.saveAs(pdfTempPath);

    const pdfBuffer = await fs.readFile(pdfTempPath);
    
    console.log('Cleaning up temp files');
    // Clean up temp files
    await fs.unlink(pdfTempPath);
    await fs.unlink(jsonTempPath);

    res.contentType('application/pdf');
    res.send(pdfBuffer);

    await context.close();
    await browser.close();
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`PDF service listening at V2 http://localhost:${port}`);
}); 