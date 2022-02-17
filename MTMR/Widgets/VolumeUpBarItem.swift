//
//  VolumeUpBarItem.swift
//  MTMR
//
//  Created by Fedor Zaitsev on 4/27/20.
//  Copyright © 2020 Anton Palgunov. All rights reserved.
//

import Foundation

class VolumeUpBarItem: CustomButtonTouchBarItem {
    override class var typeIdentifier: String {
        return "volumeUp"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.setImage(NSImage(named: NSImage.touchBarVolumeUpTemplateName)!)
        self.addAction(ItemAction(.singleTap).setHidKeyClosure(keycode: NX_KEYTYPE_SOUND_UP))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
