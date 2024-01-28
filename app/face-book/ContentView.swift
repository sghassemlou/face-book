//
//  ContentView.swift
//  face-book
//
//  Created by Fraser Lee on 2024-01-27.
//

import SwiftUI
import SwiftData

var personView: UIImageView! = nil

let DISPLAY_PORT_SIZE = 140.0

struct PersonView: UIViewRepresentable{
    var image: UIImage

    func makeUIView(context: Context) -> UIView {
        let mainView: UIView = UIView()
        let imageView: UIImageView = UIImageView()
        imageView.image = image
        imageView.frame.size.width = DISPLAY_PORT_SIZE
        imageView.frame.size.height = DISPLAY_PORT_SIZE
        imageView.contentMode = .scaleAspectFill
        mainView.addSubview(imageView)
        personView = imageView
        return mainView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}


var outputDisplay = UIView()

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    private var audioRecorder = AudioRecorder()
    
    
    var body: some View {
        // rounded rect taking up the top half of the screen with padding
        GeometryReader { geo in
            VStack(spacing:10){
                


                GeometryReader{ geo1 in
                    VStack (alignment: .trailing) {

                        HStack {
                            VStack{
                                Text("name goes here.")
                                    .font(.system(size: 25, weight: .regular, design: .rounded))

                                PersonView(image: UIImage(systemName: "faceid")!)
                                    .frame(width: DISPLAY_PORT_SIZE, height: DISPLAY_PORT_SIZE)
                                    .cornerRadius(15)
                                
                            }.frame(width: geo.size.width)
                        }
                        
                        HStack (alignment: .bottom) {
                            // Audio recording button
                            Button("Record Audio") {
                                if audioRecorder.isRecording {
                                    audioRecorder.stopRecording()
                                } else {
                                    audioRecorder.startRecording()
                                }
                            }
                            
                            Button (action: toggleCam) {
                                Image(systemName: "camera.rotate.fill")
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.white)
                                    .background(.gray)
                                    .cornerRadius(13)
                                    .imageScale(.medium)
                            }
                            
                        }

                    }.frame(width: geo.size.width, height: geo.size.height * (1/2))
                }.frame(height: geo.size.height * (1/2))
                
                HostedViewController()
                    .frame(height: geo.size.height * (1/2))
                    .cornerRadius(25.0)
            }
        }.padding(.horizontal)
    }

    private func toggleCam() {
        vc.setupVideoInput()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
