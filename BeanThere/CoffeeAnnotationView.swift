import SwiftUI

struct CoffeeAnnotationView: View {
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.title2)
            .foregroundColor(.white)
            .padding(12)
            .background(Theme.mapPin)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring()) {
                    scale = 1.0
                }
            }
    }
}

struct CoffeeAnnotationView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeAnnotationView()
    }
}
