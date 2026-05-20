import ij.*;
import ij.process.*;
import ij.plugin.*;
import java.lang.*;
import java.awt.*;
import java.awt.image.*;
import java.text.DecimalFormat;
import ij.measure.*;
import ij.plugin.filter.*;
import ij.gui.*;

public class Polar_Transformer_32bit implements PlugIn {
	int widthInitial, heightInitial, widthTransform, heightTransform;
	double centerX, centerY;
	ImageProcessor ipTransform, ipInitial;
	ImagePlus iTransform, iInitial;

	// Persistent options with default values:
	static boolean toPolar = true;
	static boolean polar180 = false; 
	static boolean defaultLines = true;
	static boolean defaultCenter = true;
	static boolean clockWise = false; 

	boolean isColor = false;
	boolean isFloat = false; 
	String title;
	static String[] op1 = { "Polar", "Cartesian" };
	static String[] op2 = { "180", "360" };
	int angleLines = 180;
	int[] rgbArray = new int[3];
	int[] xLyL = new int[3];
	int[] xLyH = new int[3];
	int[] xHyL = new int[3];
	int[] xHyH = new int[3];

	public void run(String arg) {
		iInitial = WindowManager.getCurrentImage();
		if (iInitial == null) {
			IJ.noImage();
			return;
		}
		ipInitial = iInitial.getProcessor();

		if (showDialog(ipInitial)) {

			widthInitial = ipInitial.getWidth();
			heightInitial = ipInitial.getHeight();
			
			if (ipInitial instanceof ColorProcessor)
				isColor = true;
			else if (ipInitial instanceof FloatProcessor)
				isFloat = true; 

			if (toPolar) {
				title = "Polar Transform of " + iInitial.getTitle();
				if (polar180)
					angleLines = 180;
				else
					angleLines = 360;
				if (!defaultLines)
					getLines();
				if (polar180)
					polar180();
				else
					polar360();
			} else {
				title = "Cartesian Transform of " + iInitial.getTitle();
				if (polar180)
					cart180();
				else
					cart360();
			}

			ipTransform.setMinAndMax(ipInitial.getMin(), ipInitial.getMax());
			ipTransform.setCalibrationTable(ipInitial.getCalibrationTable());
			iTransform = new ImagePlus(title, ipTransform);
			iTransform.setCalibration(iInitial.getCalibration());
			iTransform.show();
		}

	}

	public void polar180() {

		getPolarCenter();
		heightTransform = angleLines;

		double radius = Math.sqrt((centerX - 0) * (centerX - 0) + (centerY - 0)
				* (centerY - 0));
		double radiusTemp = Math.sqrt((centerX - widthInitial)
				* (centerX - widthInitial) + (centerY - 0) * (centerY - 0));
		if (radiusTemp > radius)
			radius = radiusTemp;
		radiusTemp = Math.sqrt((centerX - 0) * (centerX - 0)
				+ (centerY - heightInitial) * (centerY - heightInitial));
		if (radiusTemp > radius)
			radius = radiusTemp;
		radiusTemp = Math.sqrt((centerX - widthInitial)
				* (centerX - widthInitial) + (centerY - heightInitial)
				* (centerY - heightInitial));
		if (radiusTemp > radius)
			radius = radiusTemp;
		int radiusInt = (int) radius;
		widthTransform = radiusInt * 2 + 1;

		if (isColor)
			ipTransform = new ColorProcessor(widthTransform, heightTransform);
		else if (isFloat)
			ipTransform = new FloatProcessor(widthTransform, heightTransform);
		else
			ipTransform = new ShortProcessor(widthTransform, heightTransform);

		IJ.showStatus("Calculating...");
		for (int yy = 0; yy < heightTransform; yy++) {
			for (int xx = 0; xx < widthTransform; xx++) {

				double r = xx - radiusInt;
				double angle = (yy / (double) angleLines) * Math.PI;

				double x = getCartesianX(r, angle) + centerX;
				double y = getCartesianY(r, angle) + centerY;

				if (isColor) {
					interpolateColorPixel(x, y);
					ipTransform.putPixel(xx, yy, rgbArray);
				} else {
					double newValue = ipInitial.getInterpolatedPixel(x, y);
					ipTransform.putPixelValue(xx, yy, newValue);
				}

			}
			IJ.showProgress(yy, heightTransform);
		}
		IJ.showProgress(1.0);
	}

	public void polar360() {

		getPolarCenter();
		heightTransform = angleLines;

		double radius = Math.sqrt((centerX - 0) * (centerX - 0) + (centerY - 0)
				* (centerY - 0));
		double radiusTemp = Math.sqrt((centerX - widthInitial)
				* (centerX - widthInitial) + (centerY - 0) * (centerY - 0));
		if (radiusTemp > radius)
			radius = radiusTemp;
		radiusTemp = Math.sqrt((centerX - 0) * (centerX - 0)
				+ (centerY - heightInitial) * (centerY - heightInitial));
		if (radiusTemp > radius)
			radius = radiusTemp;
		radiusTemp = Math.sqrt((centerX - widthInitial)
				* (centerX - widthInitial) + (centerY - heightInitial)
				* (centerY - heightInitial));
		if (radiusTemp > radius)
			radius = radiusTemp;
		int radiusInt = (int) radius;
		widthTransform = radiusInt;

		if (isColor)
			ipTransform = new ColorProcessor(widthTransform, heightTransform);
		else if (isFloat)
			ipTransform = new FloatProcessor(widthTransform, heightTransform);
		else
			ipTransform = new ShortProcessor(widthTransform, heightTransform);

		IJ.showStatus("Calculating...");
		for (int yy = 0; yy < heightTransform; yy++) {
			for (int xx = 0; xx < widthTransform; xx++) {

				double r = xx;
				double angle = (yy / (double) angleLines) * Math.PI * 2;

				double x = getCartesianX(r, angle) + centerX;
				double y = getCartesianY(r, angle) + centerY;

				if (isColor) {
					interpolateColorPixel(x, y);
					ipTransform.putPixel(xx, yy, rgbArray);
				} else {
					double newValue = ipInitial.getInterpolatedPixel(x, y);
					ipTransform.putPixelValue(xx, yy, newValue);
				}

			}
			IJ.showProgress(yy, heightTransform);
		}
		IJ.showProgress(1.0);
	}

	public void cart180() {

		heightTransform = widthInitial;
		widthTransform = widthInitial;

		getCartesianCenter();

		if (isColor)
			ipTransform = new ColorProcessor(widthTransform, heightTransform);
		else if (isFloat)
			ipTransform = new FloatProcessor(widthTransform, heightTransform);
		else
			ipTransform = new ShortProcessor(widthTransform, heightTransform);

		IJ.showStatus("Calculating...");
		for (int yy = 0; yy < heightTransform; yy++) {
			for (int xx = 0; xx < widthTransform; xx++) {

				double x = xx - centerX;
				double y = yy - centerY;
				double r = getRadius(x, y);
				double angle = getAngle(x, y);

				if (angle >= 180) {
					angle = angle - 180;
					x = -r;
				} else {
					x = r;
				}

				x = x + widthInitial / 2;
				y = angle * (heightInitial / 180.0);

				if (isColor) {
					interpolateColorPixel(x, y);
					ipTransform.putPixel(xx, yy, rgbArray);
				} else {
					double newValue = ipInitial.getInterpolatedPixel(x, y);
					ipTransform.putPixelValue(xx, yy, newValue);
				}

			}
			IJ.showProgress(yy, heightTransform);
		}
		IJ.showProgress(1.0);
	}

	public void cart360() {

		heightTransform = widthInitial * 2 + 1;
		widthTransform = widthInitial * 2 + 1;

		getCartesianCenter();

		if (isColor)
			ipTransform = new ColorProcessor(widthTransform, heightTransform);
		else if (isFloat)
			ipTransform = new FloatProcessor(widthTransform, heightTransform);
		else
			ipTransform = new ShortProcessor(widthTransform, heightTransform);

		IJ.showStatus("Calculating...");
		for (int yy = 0; yy < heightTransform; yy++) {
			for (int xx = 0; xx < widthTransform; xx++) {

				double x = xx - centerX;
				double y = yy - centerY;
				double r = getRadius(x, y);
				double angle = getAngle(x, y);

				x = r;
				y = angle * (heightInitial / 360.0);

				if (isColor) {
					interpolateColorPixel(x, y);
					ipTransform.putPixel(xx, yy, rgbArray);
				} else {
					double newValue = ipInitial.getInterpolatedPixel(x, y);
					ipTransform.putPixelValue(xx, yy, newValue);
				}

			}
			IJ.showProgress(yy, heightTransform);
		}
		IJ.showProgress(1.0);
	}

	boolean showDialog(ImageProcessor ip) {
		GenericDialog gd = new GenericDialog("Polar Transformer");
		gd.addChoice("Method:", op1, op1[toPolar ? 0 : 1]);
		gd.addChoice("Degrees used for Polar Space:", op2,
				op2[polar180 ? 0 : 1]);
		gd.addCheckbox("Default_Center for Cartesian Space", defaultCenter);
		gd.addCheckbox("For_Polar_Transforms, Use 1 Line Per Angle",
				defaultLines);
		gd.addCheckbox("Clock-wise rotation", clockWise);
		gd.showDialog();
		if (gd.wasCanceled())
			return false;
		toPolar = (gd.getNextChoiceIndex() == 0);
		polar180 = (gd.getNextChoiceIndex() == 0);
		defaultCenter = gd.getNextBoolean();
		defaultLines = gd.getNextBoolean();
		clockWise = gd.getNextBoolean();
		return true;
	}

	public void getCartesianCenter() {
		centerX = widthTransform / 2;
		centerY = heightTransform / 2;
		if (!defaultCenter) {
			getCenter();
		}
	}

	public void getPolarCenter() {
		Rectangle b = new Rectangle(0, 0, widthInitial, heightInitial);
		Roi roi = iInitial.getRoi();
		if (roi != null) {
			b = roi.getBounds();
		}
		centerX = b.x + b.width / 2;
		centerY = b.y + b.height / 2;
		if (!defaultCenter) {
			getCenter();
		}
	}

	void getCenter() {
		GenericDialog gd = new GenericDialog("Center of Cartesian Grid");
		gd.addNumericField("Center_x Coordinate:", centerX, 2);
		gd.addNumericField("Center_y Coordinate:", centerY, 2);
		gd.showDialog();
		centerX = gd.getNextNumber();
		centerY = gd.getNextNumber();
	}

	void getLines() {
		GenericDialog gd = new GenericDialog("Polar Transform Options");
		gd.addNumericField("Number of Lines in Angle Dimension:", angleLines, 0);
		gd.showDialog();
		angleLines = (int) gd.getNextNumber();
	}

	double getCartesianX(double r, double angle) {
		return r * Math.cos(angle);
	}

	double getCartesianY(double r, double angle) {
		double y = r * Math.sin(angle);
		return clockWise ? -y : y;
	}

	double getRadius(double x, double y) {
		return Math.sqrt(x * x + y * y);
	}

	double getAngle(double x, double y) {
		double angle = Math.toDegrees(Math.atan2(y, x));
		if (angle < 0) {
			angle += 360;
		}
		return clockWise ? 360 - angle : angle;
	}

	void interpolateColorPixel(double x, double y) {
		int xL, yL;

		xL = (int) Math.floor(x);
		yL = (int) Math.floor(y);
		xLyL = ipInitial.getPixel(xL, yL, xLyL);
		xLyH = ipInitial.getPixel(xL, yL + 1, xLyH);
		xHyL = ipInitial.getPixel(xL + 1, yL, xHyL);
		xHyH = ipInitial.getPixel(xL + 1, yL + 1, xHyH);
		for (int rr = 0; rr < 3; rr++) {
			double newValue = (xL + 1 - x) * (yL + 1 - y) * xLyL[rr];
			newValue += (x - xL) * (yL + 1 - y) * xHyL[rr];
			newValue += (xL + 1 - x) * (y - yL) * xLyH[rr];
			newValue += (x - xL) * (y - yL) * xHyH[rr];
			rgbArray[rr] = (int) newValue;
		}
	}
}