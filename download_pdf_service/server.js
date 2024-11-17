const express = require('express');
const { chromium } = require('playwright');
const fs = require('fs').promises;
const app = express();
const port = 3004;

app.get('/download_pdf', async (req, res) => {
  const browserOptions = {
    wsEndpoint: 'ws://chrome:3000/playwright/chromium?token=6R0W53R135510'
  };

  try {
    const browser = await chromium.connect(browserOptions.wsEndpoint);
    const context = await browser.newContext({
      acceptDownloads: true,
      viewport: { width: 1200, height: 800 }
    });

    const page = await context.newPage();
    
    console.log('Navigating to https://flosscross.com/designer/');
    await page.goto('https://flosscross.com/designer/');
    await page.waitForLoadState('networkidle');

    const fileInput = await page.locator('input[type="file"]').first();
    await fileInput.setInputFiles('data/uploads/Puffins.fcjson');
    await page.waitForLoadState('networkidle');

    await page.goto('https://flosscross.com/designer/slot/1/pdf');
    await page.waitForLoadState('networkidle');

    await page.waitForSelector('button:has-text("Save To PDF")');
    await page.click('button:has-text("Save To PDF")');

    await page.waitForSelector('.q-btn__content:has-text("OK")');
    const downloadPromise = page.waitForEvent('download');
    await page.click('.q-btn__content:has-text("OK")');

    const download = await downloadPromise;
    const tempPath = '/tmp/temp.pdf';
    await download.saveAs(tempPath);

    const pdfBuffer = await fs.readFile(tempPath);
    await fs.unlink(tempPath); // Clean up temp file

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
  console.log(`PDF service listening at the http://localhost:${port}`);
}); 