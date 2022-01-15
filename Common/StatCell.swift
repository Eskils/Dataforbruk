//
//  StatCell.swift
//  TMDataViewNIB
//
//  Created by Eskil Sviggum on 12/01/2022.
//

import SwiftUI

struct StatCell: View {
    
    @State var tittel: String
    @State var eining: String?
    @Binding var verdi: String
    @Binding var prosent: Double
    @State var colors: [Color]
    @State var shouldShowProsent: Bool = true
    
    let height: CGFloat = 64
    let padding: CGFloat = 4
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                HStack(spacing: 4) {
                    Text("\(tittel): ")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        //.foregroundColor(Color(NSColor.secondaryLabelColor))
                    Text(verdi)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let eining = eining {
                        Text(eining)
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(Color.secondary)
                        
                    }
                }
                .padding(.leading, padding)
                .frame(width: geo.size.width, alignment: .leading)
                if shouldShowProsent {
                    HStack() {
                        UsageStatView(percentage: $prosent, colors: colors, lineWidth: 4)
                            .frame(width: height - 3*padding, height: height - 3*padding)
                    }
                    .padding(.trailing, padding)
                    .frame(width: geo.size.width, alignment: .trailing)
                }
            }
            .frame(width: geo.size.width, height: height, alignment: .leading)
        }
        .frame(height: height)
    }
}

struct StatCell_Previews: PreviewProvider {
    static var previews: some View {
        StatCell(tittel: "Databruk", eining: "GB", verdi: .constant("51 / 100"), prosent: .constant(0.51), colors: [.gray, .mint])
            .frame(width: 300)
    }
}
