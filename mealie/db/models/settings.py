import sqlalchemy as sa
import sqlalchemy.orm as orm
from sqlalchemy.orm import Session

from mealie.db.models._model_base import BaseMixins, SqlAlchemyBase
from mealie.db.models.recipe.category import Category, site_settings2categories


class SiteSettings(SqlAlchemyBase, BaseMixins):
    __tablename__ = "site_settings"
    id = sa.Column(sa.Integer, primary_key=True)
    language = sa.Column(sa.String)
    first_day_of_week = sa.Column(sa.Integer)
    categories = orm.relationship("Category", secondary=site_settings2categories, single_parent=True)
    show_recent = sa.Column(sa.Boolean, default=True)
    cards_per_section = sa.Column(sa.Integer)

    def __init__(
        self,
        session: Session = None,
        language="en",
        first_day_of_week: int = 0,
        categories: list = [],
        show_recent=True,
        cards_per_section: int = 9,
    ) -> None:
        session.commit()
        self.language = language
        self.first_day_of_week = first_day_of_week
        self.cards_per_section = cards_per_section
        self.show_recent = show_recent
        self.categories = [Category.get_ref(session=session, slug=cat.get("slug")) for cat in categories]

    def update(self, *args, **kwarg):
        self.__init__(*args, **kwarg)
