package com.sample.edgedetection.crop

import android.Manifest
import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import com.sample.edgedetection.SourceManager
import com.sample.edgedetection.processor.Corners
import com.sample.edgedetection.processor.cropPicture
import org.opencv.android.Utils

import org.opencv.core.Mat
import java.io.File
import java.io.FileOutputStream
import android.content.pm.PackageManager
import android.widget.Toast
import androidx.core.app.ActivityCompat
import com.sample.edgedetection.CROPPED_IMAGE_PATH
import com.sample.edgedetection.ORIGINAL_IMAGE_PATH
import com.sample.edgedetection.QUADRILATERAL
import com.sample.edgedetection.processor.getCroppedImageData


const val IMAGES_DIR = "smart_scanner"

class CropPresenter(val context: Context, private val iCropView: ICropView.Proxy) {
    private val picture: Mat? = SourceManager.pic
    private val corners: Corners? = SourceManager.corners

    init {
        val bitmap = Bitmap.createBitmap(picture?.width() ?: 1080, picture?.height()
                ?: 1920, Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(picture, bitmap, true)
        iCropView.getPaper().setImageBitmap(bitmap)
        iCropView.getPaperRect().onCorners2Crop(corners, picture?.size())
    }

    fun proceed(): Map<String, Any>? {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(context, "please grant write file permission and trya gain", Toast.LENGTH_SHORT).show()
            return null
        }

        val cornerPoints = iCropView.getPaperRect().getCorners2Crop()
        return getCroppedImageData(picture!!, cornerPoints, context.cacheDir)
    }
}