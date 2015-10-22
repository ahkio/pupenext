module PermissionHelper
  def add_item(program:, uri:, name:)
    Company.find_each do |company|
      Current.company = company.yhtio

      jarjestys = Permission.where(kuka: '', sovellus: program).maximum(:jarjestys).to_i + 10

      # Luodaan valikko
      Permission.create!(
        kuka: '',
        sovellus: program,
        nimi: uri,
        nimitys: name,
        jarjestys: jarjestys,
        laatija: 'admin',
        luontiaika: Time.now,
        muuttaja: 'admin',
        muutospvm: Time.now,
      )

      # Lisätään Admin profiiliin
      Permission.create!(
        kuka: 'Admin profiili',
        profiili: 'Admin profiili',
        paivitys: 1,
        sovellus: program,
        nimi: uri,
        nimitys: name,
        jarjestys: jarjestys,
        laatija: 'admin',
        luontiaika: Time.now,
        muuttaja: 'admin',
        muutospvm: Time.now,
      )

      # Lisätään Adminille käyttöoikeus
      admin = User.find_by(kuka: 'admin')

      if admin
        Permission.create!(
          kuka: 'admin',
          user_id: admin.tunnus,
          profiili: 'Admin profiili',
          paivitys: 1,
          sovellus: program,
          nimi: uri,
          nimitys: name,
          jarjestys: jarjestys,
          laatija: 'admin',
          luontiaika: Time.now,
          muuttaja: 'admin',
          muutospvm: Time.now,
        )
      end
    end
  end

  def remove_all(uri:)
    Company.find_each do |company|
      Current.company = company.yhtio

      Permission.where(nimi: uri).delete_all
    end
  end
end