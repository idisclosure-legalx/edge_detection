package com.sample.edgedetection.crop

import android.app.Activity
import android.content.Intent
import android.content.res.TypedArray
import android.widget.ImageView
import com.sample.edgedetection.base.BaseActivity
import com.sample.edgedetection.view.PaperRectangle
import kotlinx.android.synthetic.main.activity_crop.*
import android.view.MenuItem
import android.view.Menu
import com.sample.edgedetection.*


class CropActivity : BaseActivity(), ICropView.Proxy {

    private lateinit var mPresenter: CropPresenter

    override fun prepare() {
        proceed.setOnClickListener {
            var data = mPresenter.proceed()
            val quad = data!![QUADRILATERAL] as Array<DoubleArray>
            var intent = Intent()
            intent.putExtra(CROPPED_IMAGE_PATH, data!![CROPPED_IMAGE_PATH] as String)
            intent.putExtra(ORIGINAL_IMAGE_PATH, data!![ORIGINAL_IMAGE_PATH] as String)
            intent.putExtra(QUADRILATERAL_TOP_LEFT, quad[0])
            intent.putExtra(QUADRILATERAL_TOP_RIGHT, quad[1])
            intent.putExtra(QUADRILATERAL_BOTTOM_RIGHT, quad[2])
            intent.putExtra(QUADRILATERAL_BOTTOM_LEFT, quad[3])
            setResult(Activity.RESULT_OK, intent)

            System.gc()
            finish()
        }
    }

    override fun provideContentViewId(): Int = R.layout.activity_crop


    override fun initPresenter() {
        mPresenter = CropPresenter(this, this)
    }

    override fun getPaper(): ImageView = paper

    override fun getPaperRect(): PaperRectangle = paper_rect

    override fun getCroppedPaper(): ImageView = picture_cropped

}