#!/usr/bin/env python

import getopt, sys
from random import uniform
from pyPdf import PdfFileWriter, PdfFileReader
from reportlab.pdfgen import canvas
from reportlab.lib.colors import green

rfn = '/tmp/' + str(uniform(1, 100))
output_suffix = "pdf"
scale_ratio = 1.35

def build_watermark(SIZE, shift):
	c = canvas.Canvas(rfn, pagesize = SIZE)
	c.setFillColor(green)
	c.circle(-shift, 0, 2, fill=1)
	c.circle(SIZE[0], SIZE[1], 2, fill=1)
	c.showPage()
	c.save()

def argv_parse(argv):
	# get the name of pdf
	if len(argv) != 2:
		print "./over_crop.py {slide.pdf}"
		sys.exit()

	[filename, suffix] = argv[1].split('.')
	if suffix != "pdf":
		print "./over_crop.py {slide.pdf}"
		sys.exit()

	return filename, suffix


def main():
	filename, suffix = argv_parse(sys.argv)

	pdf = PdfFileReader(file(filename + "." + suffix, "rb"))
	output = PdfFileWriter()

	page_num = pdf.getNumPages()

	# (lower_x, upper_y)
	# v
	# +-------------------------------+ <-- (upper_x, upper_y)
	# |                               |
	# |                               |
	# |                               |
	# |                               |
	# +-------------------------------+ <-- (upper_x, lower_y)
	# ^
	# (lower_x, lower_y)
	[lower_x, lower_y, upper_x, upper_y] = map(float, pdf.getPage(0)['/MediaBox'])

	# scale_ratio = 1.35
	# TODO check the ori scal_ratio if greate than 1.35 that don't to do
	if (upper_x / upper_y) > scale_ratio:
		print 'the ratio of the slide file great than 1.35. don\'t to do anything'
		sys.exit()

	shift = ((upper_y * scale_ratio) - upper_x) / 2
	# shift = (upper_y - (upper_x / scale_ratio)) / 2

	build_watermark((upper_x + shift, upper_y), shift)
	watermark = PdfFileReader(file(rfn, "rb"))

	for i in range(page_num):
		page = pdf.getPage(i)
		page.mediaBox.lowerLeft = (lower_x - shift, lower_y)
		page.mediaBox.lowerRight = (upper_x + shift, lower_y)
		# page.mediaBox.lowerLeft = (lower_x, lower_y + shift)
		# page.mediaBox.upperLeft = (lower_x, upper_y - shift)
		page.mergePage(watermark.getPage(0))
		output.addPage(page)

	# publick out
	outputstream = file(filename + "_kindle." + suffix, "wb")
	output.write(outputstream)
	outputstream.close()

if __name__ == "__main__":
	main()

